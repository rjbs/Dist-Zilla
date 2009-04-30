package Dist::Zilla::Plugin::AutoVersion;
# ABSTRACT: take care of numbering versions so you don't have to
use Moose;
with 'Dist::Zilla::Role::VersionProvider';

use DateTime ();

=head1 DESCRIPTION

Right now, you get one format:  x.yyyymmddhhmm

In the future, this will be more tweakable.

=cut

has major => (
  is   => 'ro',
  isa  => 'Int',
  required => 1,
  default  => 1,
);

sub provide_version {
  my ($self) = @_;

  my $now = DateTime->now(time_zone => 'GMT');

  return sprintf '%s.%s',
    $self->major,
    $now->format_cldr('yyyyMMddHHmm');
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
