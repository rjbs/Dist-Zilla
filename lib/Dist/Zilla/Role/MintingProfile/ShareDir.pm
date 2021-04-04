package Dist::Zilla::Role::MintingProfile::ShareDir;
# ABSTRACT: something that keeps its minting profile in a sharedir

use Moose::Role;
with 'Dist::Zilla::Role::MintingProfile';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

use File::ShareDir;
use Dist::Zilla::Path;

=head1 DESCRIPTION

This role includes L<Dist::Zilla::Role::MintingProfile>, providing a
C<profile_dir> method that looks in the I<module>'s L<ShareDir|File::ShareDir>.

=cut

sub profile_dir {
  my ($self, $profile_name) = @_;

  my $profile_dir = path( File::ShareDir::module_dir($self->meta->name) )
                  ->child( $profile_name );

  return $profile_dir if -d $profile_dir;

  confess "Can't find profile $profile_name via $self";
}

1;
