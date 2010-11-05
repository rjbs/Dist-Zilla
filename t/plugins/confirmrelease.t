use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Test::DZil;
use Try::Tiny;

{
  try {
    my $tzil = Builder->from_config(
      { dist_root => 'corpus/dist/DZT' },
      {
        add_files => {
          'source/dist.ini' => simple_ini(
            qw(GatherDir ConfirmRelease FakeRelease)
          ),
        },
      },
    );

    $tzil->release;
  } catch {
    like(
      $_,
      qr/aborting release/i,
      "ConfirmRelease aborts by default",
    );
  }

}

for my $no (qw(n no)) {
  try {
    my $tzil = Builder->from_config(
      { dist_root => 'corpus/dist/DZT' },
      {
        add_files => {
          'source/dist.ini' => simple_ini(
            qw(GatherDir ConfirmRelease FakeRelease)
          ),
        },
      },
    );

    local $ENV{DZIL_CONFIRMRELEASE_DEFAULT} = $no;
    $tzil->release;
  } catch {
    like(
      $_,
      qr/aborting release/i,
      "ConfirmRelease aborts when DZIL_CONFIRMRELEASE_DEFAULT=$no",
    );
  }

}

for my $yes (qw(y yes)) {
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          qw(GatherDir ConfirmRelease FakeRelease)
        ),
      },
    },
  );

  local $ENV{DZIL_CONFIRMRELEASE_DEFAULT} = $yes;
  $tzil->release;

  ok(
    grep({ /Fake release happening/i } @{ $tzil->log_messages }),
    "DZIL_CONFIRMRELEASE_DEFAULT=$yes allows release"
  );
}

my $prompt = "*** Preparing to upload DZT-Sample-0.001.tar.gz to CPAN ***\n"
           . "Do you want to continue the release process?";

for my $no (qw(n no)) {
  try {
    my $tzil = Builder->from_config(
      { dist_root => 'corpus/dist/DZT' },
      {
        add_files => {
          'source/dist.ini' => simple_ini(
            qw(GatherDir ConfirmRelease FakeRelease)
          ),
        },
      },
    );

    $tzil->chrome->response_for->{$prompt} = $no;

    $tzil->release;
  } catch {
    like(
      $_,
      qr/aborting release/i,
      "ConfirmRelease aborts when answering '$no'",
    );
  }
}

for my $yes (qw(y yes)) {
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          qw(GatherDir ConfirmRelease FakeRelease)
        ),
      },
    },
  );

  $tzil->chrome->response_for->{$prompt} = $yes;

  $tzil->release;

  ok(
    grep({ /Fake release happening/i } @{ $tzil->log_messages }),
    "answering '$yes' allows release"
  );
}

done_testing;
