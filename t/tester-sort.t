use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;

my @pass_one = split /\n/, simple_ini();
my @pass_two = split /\n/, simple_ini();

is_deeply(\@pass_one, \@pass_two,  "Multiple calls to simple_ini are in the same order");

done_testing;
