#!perl
use strict;
use warnings;
use Test::More 'no_plan';
use Data::Dumper;

diag Dumper(\%ENV);
ok(1);
