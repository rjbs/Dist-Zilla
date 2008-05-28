package Dist::Zilla::Role::FileWriter;
use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'write_files';

no Moose::Role;
1;
