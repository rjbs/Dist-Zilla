use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;
use Test::Fatal;

use lib 't/lib';


sub mkconfig {
  my $root = shift;
  my $t = Builder->from_config( { dist_root => $root }, { add_files => { 'source/dist.ini' => simple_ini(@_) } } );
  $t->build;
  return $t;
}

subtest "BrokenPlugin" => sub {
  my $error = exception { mkconfig( 'corpus/dist/DZT', [ 'BrokenPlugin' => {} ] ) };

  ok( $error, "Failure occurs when a plugin is broken" );
  like( $error, qr{Compilation failed in require}, "Exception is a compilation failure" );
  like( $error, qr{This plugin is broken!},        "Exception reports the original problem" );
};

subtest "BrokenPlugin2" => sub {
  my $error = exception { mkconfig( 'corpus/dist/DZT', [ 'BrokenPlugin2' => {} ] ) };

  ok( $error, "Failure occurs when a plugin is broken" );
  like( $error, qr{Compilation failed in require}, "Exception is a compilation failure" );
  like( $error, qr{This plugin is broken!}, "Exception reports the original problem" );
};

subtest "BrokenPlugin3" => sub {
  my $error = exception { mkconfig( 'corpus/dist/DZT', [ 'BrokenPlugin3' => {} ] ) };

  ok( $error, "Failure occurs when a plugin is broken" );
  like( $error, qr{Compilation failed}, "Exception explains that it couldn't load the plugin" );
  like( $error, qr{Missing right curly or square bracket}, "Exception reports the original problem" );
};

subtest "BrokenPlugin4" => sub {
  my $error = exception { mkconfig( 'corpus/dist/DZT', [ 'BrokenPlugin4' => {} ] ) };

  ok( $error, "Failure occurs when a plugin is broken" );
  like( $error, qr{Can't locate}, "Exception explains that it couldn't load the plugin 2-layers down" );
  like( $error, qr{Some/Package/That/Does/Not/Exist/}, "Exception reports the original problem" );
};

subtest "Not::A::Plugin" => sub {
  my $error = exception { mkconfig( 'corpus/dist/DZT', [ 'Not::A::Plugin' => {} ] ) };

  ok( $error, "Failure occurs when a plugin is missing" );
  like( $error, qr{Not::A::Plugin.*isn't installed}, "Exception explains that the plugin is not installed" );
  like( $error, qr{dzil authordeps}, "Exception suggests using authordeps" );
};

done_testing;
