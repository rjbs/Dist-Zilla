package Dist::Zilla::MintingProfile::Default;
# ABSTRACT: Default minting profile provider
use Moose;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';

use File::HomeDir ();
use Path::Class;

use namespace::autoclean;

=head1 DESCRIPTION

Default minting profile provider.

This provider looks first in the F<~/.dzil/profiles/$profile_name> directory,
if not found it looks among the default profiles shipped with Dist::Zilla.

=cut

around profile_dir => sub {
  my ($orig, $self, $profile_name) = @_;

  $profile_name ||= 'default';

  my $profile_dir = dir( File::HomeDir->my_home )
                  ->subdir('.dzil', 'profiles', $profile_name);

  return $profile_dir if -d $profile_dir;

  return $self->$orig($profile_name);
};

1;
