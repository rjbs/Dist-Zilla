package Dist::Zilla::Role::TestRunner;
# ABSTRACT: something used as a delegating agent to 'dzil test'

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;

=head1 DESCRIPTION

Plugins implementing this role have their C<test> method called when
testing.  It's passed the root directory of the build test dir and an
optional hash reference of arguments.  Valid arguments include:

=for :list
* jobs -- if parallel testing is supported, this indicates how many to run at once

=method test

This method should throw an exception on failure.

=cut

requires 'test';

1;
