#!perl
use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use File::pushd qw/pushd/;
use Path::Class;
use Test::DZil;
use Dist::Zilla::App::Tester;
use YAML::Tiny;

my $tzil = Minter->_new_from_profile(
  [ Default => 'default' ],
  { name => 'DZT-Minty', },
  { global_config_root => dir('corpus/global')->absolute },
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

{
  my $result = test_dzil( $tzil->tempdir->subdir('mint')->absolute, [qw(add Foo::Bar)] );
  my $pm = dir($result->{tempdir})->file('source/lib/Foo/Bar.pm')->slurp;

  like(
    $pm,
    qr/package Foo::Bar;/,
    "our second module has the package declaration we want",
  );
}

done_testing;
