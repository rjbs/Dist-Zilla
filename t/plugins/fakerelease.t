use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Test::DZil;
use Try::Tiny;

{
  my $tzil = Dist::Zilla::Tester->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(qw(GatherDir FakeRelease)),
      },
    },
  );

  $tzil->release;

  ok(
    grep({ /fake release happen/i } @{ $tzil->log_messages }),
    "we log a fake release when we fake release",
  );
}

{
  try {
    my $tzil = Dist::Zilla::Tester->from_config(
      { dist_root => 'corpus/DZT' },
      {
        add_files => {
          'source/dist.ini' => simple_ini(qw(GatherDir FakeRelease)),
        },
      },
    );

    local $ENV{DZIL_FAKERELEASE_FAIL} = 1;
    $tzil->release;
  } catch {
    like(
      $_,
      qr/DZIL_FAKERELEASE_FAIL set, aborting/i,
      "we can make FakeRelease fail when we want!"
    );
  }
}

done_testing;
