package Dist::Zilla::Role::MintingProfile;
# ABSTRACT: something that can find a minting profile dir

use Moose::Role;

use namespace::autoclean;

use File::ShareDir;
use Path::Class;

=head1 DESCRIPTION

Plugins implementing this role should provide the C<profile_dir> method, which,
given a minting profile name, returns its directory.

The minting profile is a directory, containing arbitrary files used during
creation of new distribution. Among other things notably, it should contain the
'profile.ini' file, listing the plugins used for minter initialization.

The default implementation C<profile_dir> looks in the module's
L<ShareDir|File::ShareDir>.

After installing your profile, users will be able to start a new distribution,
based on your profile with the:

  $ dzil new -P Provider -p profile_name Distribution::Name

Furthermore, if the needs of the author is zany enough, they can override the
C<mint_dir> method, which, given a dist name, returns the directory to create
and mint the dist in. The default implementation C<mint_dir> uses the dist name.

=cut

requires 'profile_dir';

sub mint_dir {
  #my ($self, $dist_name) = @_;
  return $_[1];
}

1;
