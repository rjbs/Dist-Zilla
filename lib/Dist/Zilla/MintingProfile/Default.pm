package Dist::Zilla::MintingProfile::Default;
# ABSTRACT: Default minting profile provider

use Moose;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';

use Dist::Zilla::Dialect;

use namespace::autoclean;

use Dist::Zilla::Util;

=head1 DESCRIPTION

Default minting profile provider.

This provider looks first in the F<~/.dzil/profiles/$profile_name> directory,
if not found it looks among the default profiles shipped with Dist::Zilla.

=cut

around profile_dir => sub ($orig, $self, $profile_name) {
  $profile_name ||= 'default';

  # shouldn't look in user's config when testing
  if (!$ENV{DZIL_TESTING}) {
    my $profile_dir = Dist::Zilla::Util->_global_config_root
                    ->child('profiles', $profile_name);

    return $profile_dir if -d $profile_dir;
  }

  return $self->$orig($profile_name);
};

__PACKAGE__->meta->make_immutable;
1;
