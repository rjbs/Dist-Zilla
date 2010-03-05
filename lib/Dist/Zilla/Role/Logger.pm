package Dist::Zilla::Role::Logger;
use Moose::Role;
use namespace::autoclean;
# ABSTRACT: something that logs activity

requires 'log';
requires 'log_debug';

sub log_for_plugin       { die '...' }
sub log_debug_for_plugin { die '...' }


1;
