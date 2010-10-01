use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Test::DZil;
use YAML::Tiny;

{

  my $tzil = Builder->from_config( { dist_root => 'corpus/dist/DZT' },
    { add_files => { 'source/dist.ini' => simple_ini( [ Prereqs => { 'Test::Simple' => 0.88 } ] ) } } );
  $tzil->build;

}

done_testing;

