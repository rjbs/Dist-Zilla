use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Test::DZil;
use YAML::Tiny;

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
  $lasterror = undef if $lasterror eq "";
  $testcode->( defined $lasterror, $lasterror );
}

#
# no main_module + No Gatherdir + Legit Filesystem
#
testeval { mkconfig( 'corpus/dist/DZT', [ Prereqs => { 'Test::Simple' => 0.88 } ] )->main_module } sub {
  my ( $died, $error ) = @_;
  ok( $died, 'fails with no main_module' );
  like( $error, qr/didn't find any files in your dist/, 'tells users there are no files in dist' );
  like( $error, qr{tried to guess 'lib/DZT/Sample.pm'}, 'tells user what we expected to find' );
};

# no main_module + gatherdir + legit filesystem
#
testeval { mkconfig( 'corpus/dist/DZT', 'GatherDir', [ Prereqs => { 'Test::Simple' => 0.88 } ] )->main_module } sub {
  my ( $died, $error ) = @_;
  ok( !$died, 'should not fail with main_module' );
};

# no main_module + gatherdir + bogus filesystem
#
testeval { mkconfig( 'corpus/dist/DZT_NoPm', 'GatherDir', [ Prereqs => { 'Test::Simple' => 0.88 } ] )->main_module } sub {
  my ( $died, $error ) = @_;
  ok( $died, 'fails with no main_module' );
  like( $error, qr{tried to guess 'lib/DZT/Sample.pm'}, 'tells user what we expected to find' );
  like( $error, qr{We didn't find any \.pm files},      'tells the user there are no pm files' );
};

# bad main_module, no gatherdir, legit filesystem
#
testeval {
  mkconfig( 'corpus/dist/DZT', { main_module => 'lib/Bogus/Adventure.pm' }, [ Prereqs => { 'Test::Simple' => 0.88 } ] )
    ->main_module;
}
sub {
  my ( $died, $error ) = @_;
  ok( $died, 'should fail with missing main_module' );
  like( $error, qr/didn't find any files in your dist/, 'tells users there are no files in dist' );
  like( $error, qr{but the file 'lib/Bogus/Adventure.pm' is not to be found}, 'tells user their main_module was fubar' );
};

# bad main_module, gatherdir, legit filesystem
#
testeval {
  mkconfig( 'corpus/dist/DZT', { main_module => 'lib/Bogus/Adventure.pm' },
    'GatherDir', [ Prereqs => { 'Test::Simple' => 0.88 } ] )->main_module;
}
sub {
  my ( $died, $error ) = @_;
  ok( $died, 'should fail with missing main_module' );
  like( $error, qr{but the file 'lib/Bogus/Adventure.pm' is not to be found}, 'tells user their main_module was fubar' );
};

# bad main_module, gatherdir, bogus filesystem
#
testeval {
  mkconfig(
    'corpus/dist/DZT_NoPm', { main_module => 'lib/Bogus/Adventure.pm' },
    'GatherDir', [ Prereqs => { 'Test::Simple' => 0.88 } ]
  )->main_module;
}
sub {
  my ( $died, $error ) = @_;
  ok( $died, 'should fail with missing main_module' );
  like( $error, qr{but the file 'lib/Bogus/Adventure.pm' is not to be found}, 'tells user their main_module was fubar' );
  like( $error, qr{We didn't find any \.pm files}, 'tells the user there are no pm files' );

};

done_testing;

