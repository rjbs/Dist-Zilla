package Dist::Zilla::Role::FixedPrereqs;
# ABSTRACT: enumerate fixed (non-conditional) prerequisites
use Moose::Role;

=head1 DESCRIPTION

FixedPrereqs plugins have a C<prereq> method that should return a hashref of
prerequisite package names and versions, indicating unconditional prerequisites
to be merged together.

=cut

with 'Dist::Zilla::Role::Plugin';
requires 'prereq';

no Moose::Role;
1;
