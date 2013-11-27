package Dist::Zilla::Plugin::AutoVersion;
# ABSTRACT: take care of numbering versions so you don't have to
use Moose;
with(
  'Dist::Zilla::Role::VersionProvider',
  'Dist::Zilla::Role::TextTemplate',
);

use namespace::autoclean;

use DateTime 0.44 (); # CLDR fixes

=head1 DESCRIPTION

This plugin automatically produces a version string, generally based on the
current time.  By default, it will be in the format: 1.yyDDDn

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
  default  => 1,
);

=attr format

The format is a L<Text::Template> string that will be rendered to form the
version.  It is meant to access to one variable, C<$major>, and one subroutine,
C<cldr>, which will format the current time (in GMT) using CLDR patterns (for
which consult the L<DateTime> documentation).

The default value is:

  {{ $major }}.{{ cldr('yyDDD') }}
  {{ sprintf('%01u', ($ENV{N} || 0)) }}
  {{$ENV{DEV} ? (sprintf '_%03u', $ENV{DEV}) : ''}}

=cut

has time_zone => (
  is       => 'ro',
  isa      => 'Str',
  default  => 'GMT',
);

has format => (
  is       => 'ro',
  isa      => 'Str',
  default  => q<{{ $major }}.{{ cldr('yyDDD') }}>
            . q<{{ sprintf('%01u', ($ENV{N} || 0)) }}>
            . q<{{$ENV{DEV} ? (sprintf '_%03u', $ENV{DEV}) : ''}}>
);

sub provide_version {
  my ($self) = @_;

  my $now = DateTime->now(time_zone => $self->time_zone);

  my $version = $self->fill_in_string(
    $self->format,
    {
      major => \( $self->major ),
      cldr  => sub { $now->format_cldr($_[0]) },
    },
  );

  $self->log_debug([ 'providing version %s', $version ]);

  return $version;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 SEE ALSO

Core Dist::Zilla plugins:
L<PkgVersion|Dist::Zilla::Plugin::PkgVersion>,
L<PodVersion|Dist::Zilla::Plugin::PodVersion>,
L<NextRelease|Dist::Zilla::Plugin::NextRelease>.

Dist::Zilla roles:
L<VersionProvider|Dist::Zilla::Role::VersionProvider>,
L<TextTemplate|Dist::Zilla::Role::TextTemplate>.

=cut
