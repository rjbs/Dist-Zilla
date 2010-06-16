package Dist::Zilla::Role::TestRunner;
# ABSTRACT: something used as a delegating agent to 'dzil test'
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

=head1 DESCRIPTION

Plugins implementing this role have their C<test> method called when
testing.  It's passed the root directory of the build test dir.

=method test

This method should throw an exception on failure.

=cut

requires 'test';

no Moose::Role;
1;
