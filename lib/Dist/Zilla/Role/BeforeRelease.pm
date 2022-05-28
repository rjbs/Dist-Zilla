package Dist::Zilla::Role::BeforeRelease;
# ABSTRACT: something that runs before release really begins

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

=head1 DESCRIPTION

Plugins implementing this role have their C<before_release> method
called before the release is actually done.

=cut

requires 'before_release';

1;
