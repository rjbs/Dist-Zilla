package Dist::Zilla::Role::AfterBuild;
# ABSTRACT: something that runs after building is mostly complete
use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'after_build';

no Moose::Role;
1;
