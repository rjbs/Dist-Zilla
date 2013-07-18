use strict;
use warnings;
use Test::More 0.88;

use Test::DZil qw(Builder simple_ini);
use Test::Fatal qw(exception);

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
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
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [ '@Filter' => {
            bundle => '@FakeClassic',
            remove => 'ConfirmRelease',
          } ]
        ),
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
  like( exception {
    my $tzil = Builder->from_config(
      { dist_root => 'corpus/dist/DZT' },
      {
        add_files => {
          'source/dist.ini' => simple_ini(qw(GatherDir FakeRelease)),
        },
      },
    );

    local $ENV{DZIL_FAKERELEASE_FAIL} = 1;
    $tzil->release;
  },
  qr/DZIL_FAKERELEASE_FAIL set, aborting/i,
  "we can make FakeRelease fail when we want!"
  );
}

done_testing;
