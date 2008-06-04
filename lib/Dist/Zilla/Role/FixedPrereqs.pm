package Dist::Zilla::Role::FixedPrereqs;
# ABSTRACT: enumerate fixed (non-conditional) prerequisites
use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'prereq';

no Moose::Role;
1;
