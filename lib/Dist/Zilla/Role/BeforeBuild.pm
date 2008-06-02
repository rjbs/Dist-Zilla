package Dist::Zilla::Role::BeforeBuild;
use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'before_build';

no Moose::Role;
1;
