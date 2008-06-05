package Dist::Zilla::Role::FileWriter;
# ABSTRACT: something that writes new files into the distribution
use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'write_files';

no Moose::Role;
1;
