package Dist::Zilla::Role::MintingProfile;
# ABSTRACT: something that can find a minting profile dir

use Moose::Role;

use Dist::Zilla::Pragmas;

use namespace::autoclean;

use Dist::Zilla::Path;
use File::ShareDir;

=head1 DESCRIPTION

Plugins implementing this role should provide C<profile_dir> method, which,
given a minting profile name, returns its directory.

The minting profile is a directory, containing arbitrary files used during
creation of new distribution. Among other things notably, it should contain the
'profile.ini' file, listing the plugins used for minter initialization.

The default implementation C<profile_dir> looks in the module's
L<ShareDir|File::ShareDir>.

After installing your profile, users will be able to start a new distribution,
based on your profile with the:

  $ dzil new -P Provider -p profile_name Distribution::Name

=cut

requires 'profile_dir';

around profile_dir => sub {
  my ($orig, $self, @args) = @_;
  path($self->$orig(@args));
};

1;
