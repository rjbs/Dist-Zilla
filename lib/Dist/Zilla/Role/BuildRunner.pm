package Dist::Zilla::Role::BuildRunner;
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';
# ABSTRACT: something used as a delegating agent during 'dzil run'

requires 'build';

no Moose::Role;
1;

=head1 DESCRIPTION

Plugins implementing this role have their C<build> method called during
C<dzil run>.  It's passed the root directory of the build test dir.

=head1 REQUIRED METHODS

=head2 build

This method will throw an exception on failure.

