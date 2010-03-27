package Dist::Zilla::Role::PrereqSource;
# ABSTRACT: something that registers prerequisites
use Moose::Role;

=head1 DESCRIPTION

PrereqSource plugins have a C<register_prereqs> method that should register
prereqs with the Dist::Zilla object.

=cut

with 'Dist::Zilla::Role::Plugin';
requires 'register_prereqs';

no Moose::Role;
1;
