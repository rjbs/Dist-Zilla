package Dist::Zilla::Role::InstallTool;
# ABSTRACT: something that creates an install program for a dist
use Moose::Role;
use Moose::Autobox;

with 'Dist::Zilla::Role::Plugin';
with 'Dist::Zilla::Role::FileInjector';
requires 'setup_installer';

no Moose::Role;
1;
