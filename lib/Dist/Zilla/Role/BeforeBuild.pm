package Dist::Zilla::Role::BeforeBuild;
# ABSTRACT: something that runs before building really begins

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;

=head1 DESCRIPTION

Plugins implementing this role have their C<before_build> method called
before any other plugins are consulted.

=cut

requires 'before_build';

1;
