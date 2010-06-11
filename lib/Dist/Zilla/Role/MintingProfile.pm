package Dist::Zilla::Role::MintingProfile;
# ABSTRACT: something that can find a minting profile dir
use Moose::Role;

use File::ShareDir;
use Path::Class;

=head1 DESCRIPTION

Plugins implementing this role should provide C<profile_dir> method, which,
given a minting profile name, should return it's directory.

The minting profile is a directory, containing arbitrary files used during
creation of new distribution. Among other things notably, it should contain the
'profile.ini' file, listing the plugins used for minter initialization.

The default implementation C<profile_dir> looks in the module's
L<ShareDir|File::ShareDir>.

After installing your profile, users will be able to start a new distribution,
based on your profile with the:

  $ dzil new -P YourProfile -p profile_name Distribution::Name

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
