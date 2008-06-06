package Dist::Zilla::Role::FileGatherer;
# ABSTRACT: something that gathers files into the distribution
use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'gather_files';

no Moose::Role;
1;
