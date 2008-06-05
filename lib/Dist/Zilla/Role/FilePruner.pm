package Dist::Zilla::Role::FilePruner;
# ABSTRACT: something that removes found files from the distribution
use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'prune_files';

no Moose::Role;
1;
