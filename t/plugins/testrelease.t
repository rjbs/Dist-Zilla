use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal;

use Test::DZil;
use File::Temp qw( tempdir );

sub new_tzil {
  #my $tmpdir = tdir();
  my $tzil   = Builder->from_config(
    { dist_root => 'corpus/dist/DZT', },
    {
      add_files    => { 'source/dist.ini' => simple_ini(qw(GatherDir MakeMaker TestRelease FakeRelease)), },
    },
  );
}

sub release_happened {
  scalar grep( {/Fake release happening/i} @{ shift->log_messages } ),;
}

{
  my $tzil = new_tzil;
  is( exception { $tzil->build }, undef, "No failures occured building the release with TestRelease", );

  is( exception { $tzil->release }, undef, "No failures occured in testing the release with TestRelease", );

  note explain { root => ''. $tzil->root };
  ok( release_happened($tzil), "Release happened" );
}

done_testing;
