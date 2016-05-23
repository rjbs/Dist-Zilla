use strict;
use warnings;

use Test::More 0.88;

use File::pushd qw/pushd/;
use Dist::Zilla::Path;
use Test::DZil;
use Dist::Zilla::App::Tester;
use YAML::Tiny;

use Test::File::ShareDir -share => {
  -module => { 'Dist::Zilla::MintingProfile::Default' => 'profiles' },
};

my $tzil = Minter->_new_from_profile(
  [ Default => 'default' ],
  { name => 'DZT-Minty', },
  { global_config_root => 'corpus/global' },
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
  my $result = test_dzil( $tzil->tempdir->child('mint')->absolute, [qw(add Foo::Bar)] );
  ok(!$result->{exit_code}) || diag($result->{error});
  my $pm = path($result->{tempdir})->child('source/lib/Foo/Bar.pm')->slurp;

  like(
    $pm,
    qr/package Foo::Bar;/,
    "our second module has the package declaration we want",
  );
}

done_testing;
