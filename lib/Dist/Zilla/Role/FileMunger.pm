package Dist::Zilla::Role::FileMunger;
use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'munge_file';

no Moose::Role;
1;
