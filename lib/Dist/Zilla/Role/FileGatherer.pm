package Dist::Zilla::Role::FileGatherer;
use Moose::Autobox;
# ABSTRACT: something that gathers files into the distribution
use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
with 'Dist::Zilla::Role::FileInjector';
requires 'gather_files';

no Moose::Role;
1;
