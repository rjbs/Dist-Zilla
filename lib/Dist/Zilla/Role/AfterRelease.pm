package Dist::Zilla::Role::AfterRelease;
# ABSTRACT: something that runs after release is mostly complete
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;

=head1 DESCRIPTION

Plugins implementing this role have their C<after_release> method called
once the release is done.

=cut

requires 'after_release';

1;
