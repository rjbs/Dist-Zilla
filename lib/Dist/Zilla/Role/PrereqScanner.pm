package Dist::Zilla::Role::PrereqScanner;
# ABSTRACT: automatically extract prereqs from your modules

use Moose::Role;
with(
  'Dist::Zilla::Role::FileFinderUser' => {
    default_finders => [ ':InstallModules', ':ExecFiles' ],
  },
  'Dist::Zilla::Role::FileFinderUser' => {
    method           => 'found_test_files',
    finder_arg_names => [ 'test_finder' ],
    default_finders  => [ ':TestFiles' ],
  },
  'Dist::Zilla::Role::FileFinderUser' => {
    method           => 'found_configure_files',
    finder_arg_names => [ 'configure_finder' ],
    default_finders  => [],
  },
  'Dist::Zilla::Role::FileFinderUser' => {
    method           => 'found_develop_files',
    finder_arg_names => [ 'develop_finder' ],
    default_finders  => [ ':ExtraTestFiles' ],
  },
);

use Dist::Zilla::Dialect;

=attr finder

This is the name of a L<FileFinder|Dist::Zilla::Role::FileFinder>
whose files will be scanned to determine runtime prerequisites.  It
may be specified multiple times.  The default value is
C<:InstallModules> and C<:ExecFiles>.

=attr test_finder

Just like C<finder>, but for test-phase prerequisites.  The default
value is C<:TestFiles>.

=attr configure_finder

Just like C<finder>, but for configure-phase prerequisites.  There is
no default value; AutoPrereqs will not determine configure-phase
prerequisites unless you set configure_finder.

=attr develop_finder

Just like <finder>, but for develop-phase prerequisites.  The default value
is C<:ExtraTestFiles>.

=attr skips

This is an arrayref of regular expressions, derived from all the 'skip' lines
in the configuration.  Any module names matching any of these regexes will not
be registered as prerequisites.

=cut

has skips => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
  default => sub {  []  },
);

around mvp_multivalue_args => sub ($orig, $self) {
  ($self->$orig, 'skips')
};

around mvp_aliases => sub ($orig, $self) {
  my $aliases = $self->$orig;
  $aliases->{skip} = 'skips';
  return $aliases
};

requires 'scan_file_reqs';

sub scan_prereqs ($self) {
  require CPAN::Meta::Requirements;
  require List::Util;
  List::Util->VERSION(1.45);  # uniq

  # not a hash, because order is important
  my @sets = (
    # phase => file finder method
    [ configure => 'found_configure_files' ], # must come before runtime
    [ runtime => 'found_files'      ],
    [ test    => 'found_test_files' ],
    [ develop => 'found_develop_files' ],
  );

  my %reqs_by_phase;
  my %runtime_final;
  my @modules;

  for my $fileset (@sets) {
    my ($phase, $method) = @$fileset;

    my $req   = CPAN::Meta::Requirements->new;
    my $files = $self->$method;

    foreach my $file (@$files) {
      # skip binary files
      next if $file->is_bytes;
      # parse only perl files
      next unless $file->name =~ /\.(?:pm|pl|t|psgi)$/i
               || $file->content =~ /^#!(?:.*)perl(?:$|\s)/;
      # RT#76305 skip extra tests produced by ExtraTests plugin
      next if $file->name =~ m{^t/(?:author|release)-[^/]*\.t$};

      # store module name, to trim it from require list later on
      my @this_thing = $file->name;

      # t/lib/Foo.pm is treated as providing t::lib::Foo, lib::Foo, and Foo
      if ($this_thing[0] =~ /^t/) {
        push @this_thing, ($this_thing[0]) x 2;
        $this_thing[1] =~ s{^t/}{};
        $this_thing[2] =~ s{^t/lib/}{};
      } else {
        $this_thing[0] =~ s{^lib/}{};
      }
      s{\.pm$}{} for @this_thing;
      s{/}{::}g for @this_thing;

      # this is a bunk heuristic and can still capture strings from pod - the
      # proper thing to do is grab all packages from Module::Metadata
      push @this_thing, $file->content =~ /^[^#]*?(?:^|\s)package\s+([^\s;#]+)/mg;
      push @modules, @this_thing;

      # parse a file, and merge with existing prereqs
      $self->log_debug([ 'scanning %s for %s prereqs', $file->name, $phase ]);
      my $file_req = $self->scan_file_reqs($file);

      $req->add_requirements($file_req);

    }

    # remove prereqs from skiplist
    for my $skip ($self->skips->@*) {
      my $re   = qr/$skip/;

      foreach my $k ($req->required_modules) {
        $req->clear_requirement($k) if $k =~ $re;
      }
    }

    # remove prereqs shipped with current dist
    if (@modules) {
      $self->log_debug([
        'excluding local packages: %s',
        sub { join(', ', List::Util::uniq(@modules)) } ]
      )
    }
    $req->clear_requirement($_) for @modules;

    $req->clear_requirement($_) for qw(Config DB Errno NEXT Pod::Functions); # never indexed

    # we're done, return what we've found
    my %got = $req->as_string_hash->%*;

    if ($phase eq 'runtime') {
      %runtime_final = %got;
    } else {
      # do not test-require things required for runtime
      delete $got{$_} for
        grep { exists $got{$_} and $runtime_final{$_} ge $got{$_} }
        keys %runtime_final;
    }

    $reqs_by_phase{$phase} = \%got;
  }

  return \%reqs_by_phase
}

requires 'dump_config'; # via Dist::Zilla::Role::Plugin
around dump_config => sub {
  my $orig = shift;
  my $self = shift;

  my $config = $self->$orig;

  $config->{+__PACKAGE__} = {
    (map { $_ => [ sort @{ $self->$_ // [] } ] } qw(finder test_finder configure_finder skips)),
  };

  return $config;
};

1;
__END__

=head1 SEE ALSO

L<Dist::Zilla::Plugin::AutoPrereqs>.

=head1 CREDITS

The role was provided by Olivier Mengué (DOLMEN) and Philippe Bruhat (BOOK) at Perl QA Hackathon 2016
(but it is just a refactor of the AutoPrereqs plugin).

=cut

