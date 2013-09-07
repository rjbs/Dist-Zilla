package Dist::Zilla::Plugin::AutoPrereqs;
use Moose;
with(
  'Dist::Zilla::Role::PrereqSource',
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
);

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

=cut

use namespace::autoclean;

# ABSTRACT: automatically extract prereqs from your modules

use Moose::Autobox;

=head1 SYNOPSIS

In your F<dist.ini>:

  [AutoPrereqs]
  skip = ^Foo|Bar$
  skip = ^Other::Dist

=head1 DESCRIPTION

This plugin will extract loosely your distribution prerequisites from
your files using L<Perl::PrereqScanner>.

If some prereqs are not found, you can still add them manually with the
L<Prereqs|Dist::Zilla::Plugin::Prereqs> plugin.

This plugin will skip the modules shipped within your dist.

=attr extra_scanners

This is an arrayref of scanner names (as expected by Perl::PrereqScanner).
It will be passed as the C<extra_scanners> parameter to Perl::PrereqScanner.

=attr scanners

This is an arrayref of scanner names (as expected by Perl::PrereqScanner).
If present, it will be passed as the C<scanners> parameter to
Perl::PrereqScanner, which means that it will replace the default list
of scanners.

=attr skips

This is an arrayref of regular expressions, derived from all the 'skip' lines
in the configuration.  Any module names matching any of these regexes will not
be registered as prerequisites.

=head1 SEE ALSO

L<Prereqs|Dist::Zilla::Plugin::Prereqs>, L<Perl::PrereqScanner>.

=head1 CREDITS

This plugin was originally contributed by Jerome Quelin.

=cut

sub mvp_multivalue_args { qw(extra_scanners scanners skips) }
sub mvp_aliases { return { extra_scanner => 'extra_scanners',
                           scanner => 'scanners', skip => 'skips' } }

has extra_scanners => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
  default => sub { [] },
);

has scanners => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
  predicate => 'has_scanners',
);

has skips => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
);

sub register_prereqs {
  my $self  = shift;

  require Perl::PrereqScanner;
  Perl::PrereqScanner->VERSION('1.016'); # don't skip "lib"
  require CPAN::Meta::Requirements;
  require List::MoreUtils;  # uniq

  my @modules;

  my $scanner = Perl::PrereqScanner->new(
    ($self->has_scanners ? (scanners => $self->scanners) : ()),
    extra_scanners => $self->extra_scanners,
  );

  my @sets = (
    [ configure => 'found_configure_files' ], # must come before runtime
    [ runtime => 'found_files'      ],
    [ test    => 'found_test_files' ],
  );

  my %runtime_final;

  for my $fileset (@sets) {
    my ($phase, $method) = @$fileset;

    my $req   = CPAN::Meta::Requirements->new;
    my $files = $self->$method;

    foreach my $file (@$files) {
      # parse only perl files
      next unless $file->name =~ /\.(?:pm|pl|t|psgi)$/i
               || $file->content =~ /^#!(?:.*)perl(?:$|\s)/;
      # RT#76305 skip extra tests produced by ExtraTests plugin
      next if $file->name =~ m{^t/(?:author|release)-[^/]*\.t$};

      # store module name, to trim it from require list later on
      my @this_thing = $file->name;
      if ($this_thing[0] =~ /^t/) {
        push @this_thing, ($this_thing[0]) x 2;
        $this_thing[1] =~ s{^t/}{};
        $this_thing[2] =~ s{^t/lib/}{};
      } else {
        $this_thing[0] =~ s{^lib/}{};
      }
      @this_thing = List::MoreUtils::uniq @this_thing;
      s{\.pm$}{} for @this_thing;
      s{/}{::}g for @this_thing;
      push @modules, @this_thing;

      # parse a file, and merge with existing prereqs
      my $file_req = $scanner->scan_string($file->content);

      $req->add_requirements($file_req);
    }

    # remove prereqs shipped with current dist
    $req->clear_requirement($_) for @modules;

    $req->clear_requirement($_) for qw(Config Errno); # never indexed

    # remove prereqs from skiplist
    for my $skip (($self->skips || [])->flatten) {
      my $re   = qr/$skip/;

      foreach my $k ($req->required_modules) {
        $req->clear_requirement($k) if $k =~ $re;
      }
    }

    # we're done, return what we've found
    my %got = %{ $req->as_string_hash };
    if ($phase eq 'runtime') {
      %runtime_final = %got;
    } else {
      delete $got{$_} for
        grep { exists $got{$_} and $runtime_final{$_} ge $got{$_} }
        keys %runtime_final;
    }

    $self->zilla->register_prereqs({ phase => $phase }, %got);
  }
}

__PACKAGE__->meta->make_immutable;
1;
