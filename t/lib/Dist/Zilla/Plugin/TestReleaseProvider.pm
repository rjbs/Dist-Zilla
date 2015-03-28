package Dist::Zilla::Plugin::TestReleaseProvider;

use Moose;
with(
  'Dist::Zilla::Role::ReleaseStatusProvider',
);

sub provide_release_status { 'unstable' }

__PACKAGE__->meta->make_immutable;
1;
