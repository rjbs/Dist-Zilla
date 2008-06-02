package Dist::Zilla::Role::FixedPrereqs;
use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'prereq';

no Moose::Role;
1;
