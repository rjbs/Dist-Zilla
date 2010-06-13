package Dist::Zilla::Role::Stash::Authors;
use Moose::Role;
with 'Dist::Zilla::Role::Stash';
# ABSTRACT: a stash that provides a list of author strings

requires 'authors';

1;
