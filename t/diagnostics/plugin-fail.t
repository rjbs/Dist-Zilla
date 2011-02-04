
use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Test::DZil;

sub mkconfig {
  my $root = shift;
  my $t = Builder->from_config( { dist_root => $root }, { add_files => { 'source/dist.ini' => simple_ini(@_) } } );
  $t->build;
  return $t;
}

sub testeval(&&) {
  my ( $evaler, $testcode ) = @_;
  local $@;
  eval { $evaler->(); };
  my $lasterror = $@;

  $testcode->( defined $lasterror, $lasterror );
}

testeval {
  mkconfig( 'corpus/dist/DZT', [ 'BrokenPlugin' => {} ] );
}
sub {
  my ( $died, $error ) = @_;
  subtest "BrokenPlugin" => sub {
    ok( $died, "Failure occurs when a plugin is broken" );
    like( $error, qr{Compilation failed in require}, "Exception is a compilation failure" );
    like( $error, qr{This plugin is broken!},        "Exception reports the original problem" );

  };
};

testeval {
  mkconfig( 'corpus/dist/DZT', [ 'BrokenPlugin2' => {} ] );
}
sub {
  my ( $died, $error ) = @_;
  subtest "BrokenPlugin2" => sub {
    ok( $died, "Failure occurs when a plugin is broken" );
    like( $error, qr{Compilation failed in require}, "Exception is a compilation failure" );

    like( $error, qr{This plugin is broken!}, "Exception reports the original problem" );

  };
};

testeval {
  mkconfig( 'corpus/dist/DZT', [ 'BrokenPlugin3' => {} ] );
}
sub {
  my ( $died, $error ) = @_;
  subtest "BrokenPlugin3" => sub {
    ok( $died, "Failure occurs when a plugin is broken" );
    like( $error, qr{Compilation failed}, "Exception explains that it couldn't load the plugin" );
    like( $error, qr{Missing right curly or square bracket}, "Exception reports the original problem" );

  };
};

testeval {
  mkconfig( 'corpus/dist/DZT', [ 'BrokenPlugin4' => {} ] );
}
sub {
  my ( $died, $error ) = @_;
  subtest "BrokenPlugin4" => sub {
    ok( $died, "Failure occurs when a plugin is broken" );
    like( $error, qr{Can't locate}, "Exception explains that it couldn't load the plugin 2-layers down" );
    like( $error, qr{Some/Package/That/Does/Not/Exist/}, "Exception reports the original problem" );

  };
};

testeval {
  mkconfig( 'corpus/dist/DZT', [ 'Not::A::Plugin' => {} ] );
}
sub {
  my ( $died, $error ) = @_;
  subtest "Not::A::Plugin" => sub {
    ok( $died, "Failure occurs when a plugin is missing" );
    like( $error, qr{Not::A::Plugin.*does not appear to be installed}, "Exception explains that the plugin is not installed" );
    like( $error, qr{dzil authordeps}, "Exception suggests using authordeps" );

  };
};

done_testing;
