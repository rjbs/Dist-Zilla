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

my $pm = $tzil->slurp_file('mint/DZT-Minty/lib/DZT/Minty.pm');

like(
  $pm,
  qr/package DZT::Minty;/,
  "our new module has the package declaration we want",
);

done_testing;
