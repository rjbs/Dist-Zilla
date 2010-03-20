use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Test::DZil;
use Try::Tiny;

my $changes = <<'END_CHANGES';
Revision history for {{$dist->next}}

{{$NEXT}}
          got included in an awesome test suite

1.200300  2009-01-02
          finally left home, proving to mom I can make it!

END_CHANGES

if (0) {
  my $tzil = Dist::Zilla::Tester->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/Changes' => $changes,
        'source/dist.ini' => simple_ini(qw(AllFiles NextRelease FakeRelease)),
      },
    },
  );

  $tzil->build;
  $tzil->release;

  ok(
    grep({ /fake release happen/i } @{ $tzil->log_messages }),
    "we log a fake release when we fake release",
  );
}

{
  my $tzil = Dist::Zilla::Tester->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/Changes' => $changes,
        'source/dist.ini' => simple_ini(qw(AllFiles FakeRelease)),
      },
    },
  );

  try {
    local $ENV{DZIL_FAKERELEASE_FAIL} = 1;
    $tzil->build;
    $tzil->release;
  } catch {
    like(
      $_,
      qr/DZIL_FAKERELEASE_FAIL set, aborting/i,
      "we can make FakeRelease fail when we want!"
    );
  };
}

done_testing;
