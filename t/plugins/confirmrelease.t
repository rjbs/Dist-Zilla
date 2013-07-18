use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal;
use Test::Deep;
use Test::DZil;

sub new_tzil {
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' =>
          simple_ini(qw(GatherDir ConfirmRelease FakeRelease)),
      },
    },
  );
}

sub release_happened {
  scalar grep({/Fake release happening/i} @{ shift->log_messages }),;
}

my $release_aborted = qr/aborting release/i;

{
  my $tzil = new_tzil;

  like(
    exception { $tzil->release },
    $release_aborted,
    "ConfirmRelease aborts by default",
  );

  ok(!release_happened($tzil), "release did not happen by default");
}

for my $no (qw(n no)) {
  local $ENV{DZIL_CONFIRMRELEASE_DEFAULT} = $no;

  my $tzil = new_tzil;

  like(
    exception { $tzil->release },
    $release_aborted,
    "ConfirmRelease aborts when DZIL_CONFIRMRELEASE_DEFAULT=$no",
  );

  ok(
    !release_happened($tzil),
    "release did not happen when DZIL_CONFIRMRELEASE_DEFAULT=$no",
  );
}

for my $yes (qw(y yes)) {
  local $ENV{DZIL_CONFIRMRELEASE_DEFAULT} = $yes;

  my $tzil = new_tzil;

  is(
    exception { $tzil->release },
    undef,
    "DZIL_CONFIRMRELEASE_DEFAULT=$yes no exception",
  );

  ok(
    release_happened($tzil),
    "DZIL_CONFIRMRELEASE_DEFAULT=$yes allows release",
  );
}


my $prompt = "Do you want to continue the release process?";

for my $no (qw(n no)) {
  my $tzil = new_tzil;

  $tzil->chrome->set_response_for($prompt, $no);

  like(
    exception { $tzil->release },
    $release_aborted,
    "ConfirmRelease aborts when answering '$no'",
  );

  cmp_deeply(
    $tzil->log_messages,
    supersetof("[ConfirmRelease] *** Preparing to release DZT-Sample-0.001.tar.gz with FakeRelease ***"),
    'supplementary information was also displayed',
  ) or diag explain $tzil->log_messages;

  ok(!release_happened($tzil), "release did not happen when answering '$no'");
}

for my $yes (qw(y yes)) {
  my $tzil = new_tzil;

  $tzil->chrome->set_response_for($prompt, $yes);

  is(
    exception { $tzil->release },
    undef,
    "ConfirmRelease no exception when answering '$yes'",
  );

  cmp_deeply(
    $tzil->log_messages,
    supersetof("[ConfirmRelease] *** Preparing to release DZT-Sample-0.001.tar.gz with FakeRelease ***"),
    'supplementary information was also displayed',
  ) or diag explain $tzil->log_messages;

  ok(release_happened($tzil), "answering '$yes' allows release");
}

done_testing;
