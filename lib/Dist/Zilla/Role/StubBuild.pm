package Dist::Zilla::Role::StubBuild;
# ABSTRACT: provides an empty BUILD methods

use Moose::Role;

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

sub BUILD {}

no Moose::Role;
1;
