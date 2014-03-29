use strict;
use warnings;
use Test::More 0.88;
use utf8;

use lib 't/lib';

use Test::DZil;
use Test::Fatal;

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

  like(
    exception {
      local $ENV{DZIL_FAKERELEASE_FAIL} = 1;
      $tzil->release;
    },
    qr/DZIL_FAKERELEASE_FAIL set, aborting/i,
    "we can make FakeRelease fail when we want!"
  );

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

{
  local $ENV{TRIAL} = 1;

  my $tzil_trial = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/Changes' => $changes,
        'source/dist.ini' => simple_ini(
          qw(GatherDir NextRelease FakeRelease)
        ),
      },
    },
  );

  $tzil_trial->build;

  like(
    $tzil_trial->slurp_file('build/Changes'),
    # not using /m here because it stinks on 5.8.8
    qr{0\.001 .+ \(TRIAL RELEASE\)},
    "adding -TRIAL works",
  );
}

{
  local $ENV{TRIAL} = 1;

  my $tzil_trial = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/Changes' => $changes,
        'source/dist.ini' => simple_ini(
                'GatherDir',
                [ NextRelease => { format => "%v%T", } ],
                'FakeRelease',
        ),
      },
    },
  );

  $tzil_trial->build;

  like(
    $tzil_trial->slurp_file('build/Changes'),
    qr{0.001-TRIAL},
    "adding -TRIAL works",
  );
}

{
  local $ENV{TRIAL} = 1;

  my $tzil_trial = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/Changes' => $changes,
        'source/dist.ini' => simple_ini(
                'GatherDir',
                [ NextRelease => { format => "%-12V ohhai", } ],
                'FakeRelease',
        ),
      },
    },
  );

  $tzil_trial->build;

  like(
    $tzil_trial->slurp_file('build/Changes'),
    qr{0.001-TRIAL  ohhai},
    "adding -TRIAL with padding works",
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
                [ NextRelease => { format => "%v %U %E", } ],
                'FakeRelease',
        ),
      },
    },
  );

  like(
    exception { $tzil->build },
    qr{\QYou must enter your name in the [%User] section\E},
    "complains about missing name",
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
                [ NextRelease => { format => "%v %U <%E>", } ],
                'FakeRelease',
                [ '%User' => { name  => 'E.X. Ample',
                               email => 'me@example.com' } ],
        ),
      },
    },
  );

  is(
    exception { $tzil->build },
    undef,
    "build successfully with name & email",
  );

  like(
    $tzil->slurp_file('build/Changes'),
    qr{^0\.001 E\.X\. Ample <me\@example\.com>}m,
    "adding name and email works",
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
                [ NextRelease => { format => "%v %U <%E>",
                                   user_stash => '%Info' } ],
                'FakeRelease',
                [ '%User' => '%Info' => { name  => 'E.X. Ample',
                                          email => 'me@example.com' } ],
        ),
      },
    },
  );

  is(
    exception { $tzil->build },
    undef,
    "build successfully with %Info stash",
  );

  like(
    $tzil->slurp_file('build/Changes'),
    qr{^0\.001 E\.X\. Ample <me\@example\.com>}m,
    "adding name and email from %Info works",
  );
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZ-NonAscii' },
  );

  $tzil->build;

  like(
    $tzil->slurp_file('build/Changes'),
    qr{Olivier Mengué},
    "dolmen's name is unmangled",
  );
}

done_testing;
