use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use autodie;
use Test::DZil;

my $with_version = '
package DZT::WVer;
our $VERSION = 1.234;
1;
';

my $two_packages = '
package DZT::TP1;

package DZT::TP2;

1;
';

my $repeated_packages = '
package DZT::R1;

package DZT::R2;

package DZT::R1;

1;
';

my $monkey_patched = '
package DZT::TP1;

package
 DZT::TP2;

1;
';

sub version_re {
  my ($mod, $ver) = @_;
  return qr|^BEGIN {\s+\$\Q${mod}::VERSION = '$ver';\E }$|m,
}

my $tzil = Dist::Zilla::Tester->from_config(
  { dist_root => 'corpus/DZT' },
  {
    add_files => {
      'source/lib/DZT/TP1.pm'    => $two_packages,
      'source/lib/DZT/WVer.pm'   => $with_version,
      'source/lib/DZT/R1.pm'     => $repeated_packages,
      'source/lib/DZT/Monkey.pm' => $monkey_patched,
      'source/dist.ini' => simple_ini('GatherDir', 'PkgVersion'),
    },
  },
);

$tzil->build;

my $dzt_sample = $tzil->slurp_file('build/lib/DZT/Sample.pm');
like(
  $dzt_sample,
  version_re('DZT::Sample', '0.001'),
  "added version to DZT::Sample",
);

my $dzt_tp1 = $tzil->slurp_file('build/lib/DZT/TP1.pm');
like(
  $dzt_tp1,
  version_re('DZT::TP1', '0.001'),
  "added version to DZT::TP1",
);

like(
  $dzt_tp1,
  version_re('DZT::TP2', '0.001'),
  "added version to DZT::TP2",
);

my $dzt_wver = $tzil->slurp_file('build/lib/DZT/WVer.pm');
unlike(
  $dzt_wver,
  version_re('DZT::WVer', '0.001'),
  "*not* added to DZT::WVer; we have one already",
);

ok(
  grep({ m(skipping lib/DZT/WVer\.pm: assigns to \$VERSION) }
    @{ $tzil->log_messages }),
  "we report the reason for no updateing WVer",
);

my $dzt_r1 = $tzil->slurp_file('build/lib/DZT/R1.pm');
my @matches = grep { /R1::VER/ } split /\n/, $dzt_r1;
is(@matches, 1, "we add at most 1 VERSION per package");

my $dzt_monkey = $tzil->slurp_file('build/lib/DZT/Monkey.pm');
unlike(
  $dzt_monkey,
  qr{\$DZT::TP2::VERSION},
  "no version for DZT::TP2 when it looks like a monkey patch"
);

ok(
  grep({ m(skipping .+ DZT::TP2) } @{ $tzil->log_messages }),
  "we report the reason for not updating Monkey",
);

done_testing;

