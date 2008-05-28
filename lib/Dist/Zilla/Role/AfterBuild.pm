package Dist::Zilla::Role::AfterBuild;
use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'after_build';

no Moose::Role;
1;
