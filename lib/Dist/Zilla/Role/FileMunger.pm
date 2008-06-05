package Dist::Zilla::Role::FileMunger;
# ABSTRACT: something that alters a file's destination or content
use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'munge_file';

no Moose::Role;
1;
