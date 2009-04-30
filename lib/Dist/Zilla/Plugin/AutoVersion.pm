package Dist::Zilla::Plugin::AutoVersion;
# ABSTRACT: take care of numbering versions so you don't have to
use Moose;
with(
  'Dist::Zilla::Role::VersionProvider',
  'Dist::Zilla::Role::TextTemplate',
);

use DateTime ();

=head1 DESCRIPTION

This plugin automatically produces a version string, generally based on the
current time.  By default, it will be in the format: 1.yyyymmddhhmm

=cut

=attr major

The C<major> attribute is just an integer that is meant to store the major
version number.  If no value is specified in configuration, it will default to
1.

This attribute's value can be referred to in the autoversion format template.

=cut

has major => (
  is   => 'ro',
  isa  => 'Int',
  required => 1,
  default  => 1,
);

=attr format

The format is a L<Text::Template> string that will be rendered to form the
version.  It is meant to access to one variable, C<$major>, and one subroutine,
C<cldr>, which will format the current time (in GMT) using CLDR patterns (for
which consult the L<DateTime> documentation).

The default value is:

  {{ $major }}.{{ cldr('yyDDD') }}0

=cut

has format => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
  default  => q[{{ $major }}.{{ cldr('yyDDD') }}0],
);

sub provide_version {
  my ($self) = @_;

  my $now = DateTime->now(time_zone => 'GMT');

  my $version = $self->fill_in_string(
    $self->format,
    {
      major => \( $self->major ),
      cldr  => sub { $now->format_cldr($_[0]) },
    },
  );
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
