package Dist::Zilla::Role::Stash::Login;
use Moose::Role;
with 'Dist::Zilla::Role::Stash';
# ABSTRACT: a stash with username/password credentials

requires 'username';
requires 'password';

1;
