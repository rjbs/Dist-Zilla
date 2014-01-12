package Dist::Zilla::Role::AfterBuild;
# ABSTRACT: something that runs after building is mostly complete

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;

=head1 DESCRIPTION

Plugins implementing this role have their C<after_build> method called once all
the files have been written out.  It is passed a hashref with the following
data:

  build_root - the directory in which the dist was built

=cut

requires 'after_build';

1;
