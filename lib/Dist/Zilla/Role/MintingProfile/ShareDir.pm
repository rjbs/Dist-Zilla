package Dist::Zilla::Role::MintingProfile::ShareDir;
# ABSTRACT: something that keeps its minting profile in a sharedir
use Moose::Role;
with 'Dist::Zilla::Role::MintingProfile';

use File::ShareDir;
use Path::Class;

=head1 DESCRIPTION

This role includes L<Dist::Zilla::Role::MintingProfile>, providing a
C<profile_dir> method that looks in the I<module>'s L<ShareDir|File::ShareDir>.

=cut

sub profile_dir {
  my ($self, $profile_name) = @_;

  my $profile_dir = dir( File::ShareDir::module_dir($self->meta->name) )
                  ->subdir( $profile_name );

  return $profile_dir if -d $profile_dir;

  confess "Can't find profile $profile_name via $self";
}

no Moose::Role;
1;
