package Dist::Zilla::Role::TestRunner;

# ABSTRACT: something used as a delegating agent to 'dzil test'

use Moose::Role;

=head1 DESCRIPTION

Plugins implementing this role have their C<test> method called when
testing.  It's passed the root directory of the build test dir.

=cut

with 'Dist::Zilla::Role::Plugin';

=head1  REQUIRED METHODS

=head2 test

  ->test( $build_dir )

=cut

requires 'test';

no Moose::Role;
1;
