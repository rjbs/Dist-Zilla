package Dist::Zilla::Role::PrereqSource;
# ABSTRACT: something that registers prerequisites

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

=head1 DESCRIPTION

PrereqSource plugins have a C<register_prereqs> method that should register
prereqs with the Dist::Zilla object.

=cut

requires 'register_prereqs';

1;
