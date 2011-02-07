use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Test::DZil;
use Try::Tiny;

local $ENV{TZ} = 'America/New_York';

my $changes = <<'END_CHANGES';
Revision history for {{$dist->name}}

{{$NEXT}}
          got included in an awesome test suite

0.000     2009-01-02
          finally left home, proving to mom I can make it!

END_CHANGES

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/Changes' => $changes,
        'source/dist.ini' => simple_ini(qw(GatherDir NextRelease FakeRelease)),
      },
    },
  );

  $tzil->build;

  like(
    $tzil->slurp_file('build/Changes'),
    qr{0\.001},
    "new version appears in build Changes file",
  );

  unlike(
    $tzil->slurp_file('source/Changes'),
    qr{0\.001},
    "new version does not yet appear in source Changes file",
  );

  unlike(
    $tzil->slurp_file('build/Changes'),
    qr{\r},
    "no \\r added to build Changelog",
  );

  $tzil->release;

  like(
    $tzil->slurp_file('source/Changes'),
    qr{0\.001},
    "new version appears in source Changes file after release",
  );

  ok(
    grep({ /fake release happen/i } @{ $tzil->log_messages }),
    "we log a fake release when we fake release",
  );

  unlike(
    $tzil->slurp_file('source/Changes'),
    qr{\r},
    "No new \\r's added to post-release changelog",
  );
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/Changes' => $changes,
        'source/dist.ini' => simple_ini(qw(GatherDir NextRelease FakeRelease)),
      },
    },
  );

  $tzil->build;

  like(
    $tzil->slurp_file('build/Changes'),
    qr{0\.001},
    "new version appears in build Changes file",
  );

  unlike(
    $tzil->slurp_file('source/Changes'),
    qr{0\.001},
    "new version does not yet appear in source Changes file",
  );

  try {
    local $ENV{DZIL_FAKERELEASE_FAIL} = 1;
    $tzil->release;
  } catch {
    like(
      $_,
      qr/DZIL_FAKERELEASE_FAIL set, aborting/i,
      "we can make FakeRelease fail when we want!"
    );
  };

  unlike(
    $tzil->slurp_file('source/Changes'),
    qr{0\.001},
    "no new version in source Changes after failed release",
  );
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/Changes' => $changes,
        'source/dist.ini' => simple_ini(
                'GatherDir',
                [ NextRelease => { format => "** FOOTASTIC %-9v", } ],
                'FakeRelease',
        ),
      },
    },
  );

  $tzil->build;

  like(
    $tzil->slurp_file('build/Changes'),
    qr{FOOTASTIC},
    "setting a custom format works",
  );
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/Changes' => $changes,
        'source/dist.ini' => simple_ini(
                'GatherDir',
                [ NextRelease => { time_zone => 'UTC', } ],
                'FakeRelease',
        ),
      },
    },
  );

  $tzil->build;

  like(
    $tzil->slurp_file('build/Changes'),
    qr{UTC},
    "setting a custom time_zone works",
  );
}

done_testing;
