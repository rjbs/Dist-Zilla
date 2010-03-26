package Dist::Zilla::Plugin::AutoPrereq;
use Moose;
with(
  'Dist::Zilla::Role::FixedPrereqs',
  'Dist::Zilla::Role::FileFinderUser' => {
    default_finders => [ ':InstallModules', ':ExecFiles' ],
  },
  'Dist::Zilla::Role::FileFinderUser' => {
    method           => 'found_test_files',
    finder_arg_names => [ 'test_finder' ],
    default_finders  => [ ':TestFiles' ],
  },
);

# ABSTRACT: automatically extract prereqs from your modules

use Perl::PrereqScanner 0.100830; # bugfixes
use PPI;
use Version::Requirements 0.100630;  # merge with 0-min bug
use version;

=for Pod::Coverage prereq

=head1 SYNOPSIS

In your F<dist.ini>:

  [AutoPrereq]
  skip = ^Foo|Bar$

=head1 DESCRIPTION

This plugin will extract loosely your distribution prerequisites from
your files using L<Perl::PrereqScanner>.

If some prereqs are not found, you can still add them manually with the
L<Dist::Zilla::Plugin::Prereq> plugin.

This plugin will skip the modules shipped within your dist.

The module accept the following options:

=for :list
= skip
a regex that will remove any matching modules found from prereqs

=cut

# -- attributes

# skiplist - a regex
has skip => (
  is => 'ro',
  predicate => 'has_skip',
);

# -- public methods

sub prereq {
  my $self  = shift;

  my $req = Version::Requirements->new;
  my @modules;

  my @sets = (
    [ runtime => 'found_files'      ],
    [ test    => 'found_test_files' ],
  );

  my %runtime_final;

  for my $fileset (@sets) {
    my ($phase, $method) = @$fileset;

    my $files = $self->$method;

    foreach my $file (@$files) {
      # parse only perl files
      next unless $file->name =~ /\.(?:pm|pl|t)$/i
               || $file->content =~ /^#!(?:.*)perl(?:$|\s)/;

      # store module name, to trim it from require list later on
      my $module = $file->name;
      $module =~ s{^(?:t/)?lib/}{};
      $module =~ s{\.pm$}{};
      $module =~ s{/}{::}g;
      push @modules, $module;

      # parse a file, and merge with existing prereqs
      my $file_req = Perl::PrereqScanner->new->scan_string($file->content);

      $req->add_requirements($file_req);
    }

    # remove prereqs shipped with current dist
    $req->clear_requirement($_) for @modules;

    # remove prereqs from skiplist
    if ($self->has_skip && $self->skip) {
      my $skip = $self->skip;
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

    $self->zilla->prereq->register_prereqs({ phase => $phase }, %got);
  }

  # XXX: cheating -- rjbs, 2010-03-25
  return {};
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

