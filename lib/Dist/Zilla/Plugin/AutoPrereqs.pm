package Dist::Zilla::Plugin::AutoPrereqs;
# ABSTRACT: automatically extract prereqs from your modules

use Moose;
with(
  'Dist::Zilla::Role::PrereqSource',
  'Dist::Zilla::Role::PPI',
  'Dist::Zilla::Role::ScanPrereqs',
);

use Moose::Util::TypeConstraints 'enum';
use namespace::autoclean;

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

B<Note>, if you have any non-Perl files in your C<t/> directory or other
directories being scanned, be sure to mark those files' encoding as C<bytes>
with the L<Encoding|Dist::Zilla::Plugin::Encoding> plugin so they won't be
scanned:

    [Encoding]
    encoding = bytes
    match    = ^t/data/

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

Just like C<finder>, but for develop-phase prerequisites.  The default value
is C<:ExtraTestFiles>.

=attr skips

This is an arrayref of regular expressions, derived from all the 'skip' lines
in the configuration.  Any module names matching any of these regexes will not
be registered as prerequisites.

=attr relationship

The relationship used for the registered prerequisites. The default value is
'requires'; other options are 'recommends' and 'suggests'.

=attr extra_scanners

This is an arrayref of scanner names (as expected by L<Perl::PrereqScanner>).
It will be passed as the C<extra_scanners> parameter to L<Perl::PrereqScanner>.

=attr scanners

This is an arrayref of scanner names (as expected by L<Perl::PrereqScanner>).
If present, it will be passed as the C<scanners> parameter to
L<Perl::PrereqScanner>, which means that it will replace the default list
of scanners.

=head1 SEE ALSO

L<Prereqs|Dist::Zilla::Plugin::Prereqs>, L<Perl::PrereqScanner>.

=head1 CREDITS

This plugin was originally contributed by Jerome Quelin.

=cut

sub mvp_multivalue_args { qw(extra_scanners scanners) }
sub mvp_aliases { return { extra_scanner => 'extra_scanners',
                           scanner => 'scanners',
                           relationship => 'type' } }

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


has _scanner => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $self = shift;

    require Perl::PrereqScanner;
    Perl::PrereqScanner->VERSION('1.016'); # don't skip "lib"

    return Perl::PrereqScanner->new(
      ($self->has_scanners ? (scanners => $self->scanners) : ()),
      extra_scanners => $self->extra_scanners,
    )
  },
  init_arg => undef,
);

has type => (
  is => 'ro',
  isa => enum([qw(requires recommends suggests)]),
  default => 'requires',
);

sub scan_file_reqs {
  my ($self, $file) = @_;
  return $self->_scanner->scan_ppi_document($self->ppi_document_for_file($file))
}

sub register_prereqs {
  my $self  = shift;

  my $type = $self->type;

  my $reqs_by_phase = $self->scan_prereqs;
  while (my ($phase, $reqs) = each %$reqs_by_phase) {
    $self->zilla->register_prereqs({ phase => $phase, type => $type }, %$reqs);
  }
}

__PACKAGE__->meta->make_immutable;
1;
