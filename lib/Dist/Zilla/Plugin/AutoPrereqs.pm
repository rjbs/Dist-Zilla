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
);

# ABSTRACT: automatically extract prereqs from your modules

use Moose::Autobox;
use Perl::PrereqScanner 0.100830; # bugfixes
use PPI;
use Version::Requirements 0.100630;  # merge with 0-min bug
use version;

=head1 SYNOPSIS

In your F<dist.ini>:

  [AutoPrereqs]
  skip = ^Foo|Bar$

=head1 DESCRIPTION

This plugin will extract loosely your distribution prerequisites from
your files using L<Perl::PrereqScanner>.

If some prereqs are not found, you can still add them manually with the
L<Dist::Zilla::Plugin::Prereqs> plugin.

This plugin will skip the modules shipped within your dist.

=attr skips

This is an arrayref of regular expressions.  Any module names matching
any of theseregex will not be registered as prerequisites.

=head1 CREDITS

This plugin was originally contributed by Jerome Quelin.

=cut

sub mvp_multivalue_args { qw(skips) }
sub mvp_aliases { return { skip => 'skips' } }

has skips => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
  handles => {
     has_skips => 'count',
  },
);

sub register_prereqs {
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

no Moose;
__PACKAGE__->meta->make_immutable;
1;

