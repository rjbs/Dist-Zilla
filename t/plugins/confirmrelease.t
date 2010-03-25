use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Test::DZil;
use Try::Tiny;

{
  try {
    my $tzil = Dist::Zilla::Tester->from_config(
      { dist_root => 'corpus/DZT' },
      {
        add_files => {
          'source/dist.ini' => simple_ini(qw(GatherDir ConfirmRelease FakeRelease)),
        },
      },
    );

    local $ENV{PERL_MM_USE_DEFAULT} = 1;
    $tzil->release;
  } catch {
    like(
      $_,
      qr/aborting release/i,
      "ConfirmRelease aborts by default",
    );
  }

}

{
  my $tzil = Dist::Zilla::Tester->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(qw(GatherDir FakeRelease)),
      },
    },
  );

  local $ENV{PERL_MM_USE_DEFAULT} = 1;
  local $ENV{DZIL_CONFIRMRELEASE_DEFAULT} = "y";
  $tzil->release;

  ok(
    grep({ /Fake release happening/i } @{ $tzil->log_messages }),
    "DZIL_CONFIRMRELEASE_DEFAULT=y allows release"
  );
}

done_testing;
