#!perl
use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Path::Class;
use Test::DZil;
use YAML::Tiny;

my $tzil = Minter->_new_from_profile(
  [ Default => 'default' ],
  { name => 'DZT-Minty', },
  { global_config_root => dir('t/global')->absolute },
);

$tzil->mint_dist;

my $pm = $tzil->slurp_file('mint/lib/DZT/Minty.pm');

like(
  $pm,
  qr/package DZT::Minty;/,
  "our new module has the package declaration we want",
);

my $distini = $tzil->slurp_file('mint/dist.ini');

like(
  $distini,
  qr/copyright_holder = A. U. Thor/,
  "copyright_holder in dist.ini",
);

done_testing;
