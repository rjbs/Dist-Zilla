package Dist::Zilla::Role::FilePruner;
use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'prune_files';

no Moose::Role;
1;
