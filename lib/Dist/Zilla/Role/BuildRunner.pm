package Dist::Zilla::Role::BuildRunner;
# ABSTRACT: something used as a delegating agent during 'dzil run'

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

=head1 DESCRIPTION

Plugins implementing this role have their C<build> method called during
C<dzil run>.  It's passed the root directory of the build test dir.

=head1 REQUIRED METHODS

=head2 build

This method will throw an exception on failure.

=cut

requires 'build';

1;
