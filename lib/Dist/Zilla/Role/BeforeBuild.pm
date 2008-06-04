package Dist::Zilla::Role::BeforeBuild;
# ABSTRACT: something that runs before building really begins
use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'before_build';

no Moose::Role;
1;
