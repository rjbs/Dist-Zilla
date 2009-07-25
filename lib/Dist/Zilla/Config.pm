package Dist::Zilla::Config;
use Moose::Role;
# ABSTRACT: stored configuration loader role

requires 'read_config';

no Moose::Role;
1;
