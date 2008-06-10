package Dist::Zilla::Role::BeforeBuild;
# ABSTRACT: something that runs before building really begins
use Moose::Role;

=head1 DESCRIPTION

Plugins implementing this role have their C<before_build> method called
before any other plugins are consulted.

=cut

with 'Dist::Zilla::Role::Plugin';
requires 'before_build';

no Moose::Role;
1;
