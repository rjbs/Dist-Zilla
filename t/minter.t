#!perl
use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Test::DZil;
use YAML::Tiny;

my $tzil = Minter->_new_from_profile(
  [ Default => 'default' ],
  { name => 'DZT-Minty', },
  { global_config_root => Path::Class::dir('/Users/rjbs/.dzil') },
);

$tzil->mint_dist;

pass("didn't die!");

done_testing;
