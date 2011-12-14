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

my $with_version_two_lines = '
package DZT::WVer;
our $VERSION;
$VERSION = 1.234;
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
my $hide_me_comment = '
package DZT::HMC;

package # hide me from toolchain
 DZT::TP2;

1;
';


my $script = '
#!/usr/bin/perl

print "hello world\n";
';

my $script_pkg = '
#!/usr/bin/perl

package DZT::Script;
';

my $tzil = Builder->from_config(
  { dist_root => 'corpus/dist/DZT' },
  {
    add_files => {
      'source/lib/DZT/TP1.pm'    => $two_packages,
      'source/lib/DZT/WVer.pm'   => $with_version,
      'source/lib/DZT/WVerTwoLines.pm' => $with_version_two_lines,
      'source/lib/DZT/R1.pm'     => $repeated_packages,
      'source/lib/DZT/Monkey.pm' => $monkey_patched,
      'source/lib/DZT/HideMe.pm' => $hide_me_comment,
      'source/bin/script_pkg.pl' => $script_pkg,
      'source/bin/script_ver.pl' => $script_pkg . "our \$VERSION = 1.234;\n",
      'source/bin/script.pl'     => $script,
      'source/dist.ini' => simple_ini('GatherDir', 'PkgVersion', 'ExecDir'),
    },
  },
);

$tzil->build;

my $dzt_sample = $tzil->slurp_file('build/lib/DZT/Sample.pm');
like(
  $dzt_sample,
  qr{^\s*\$\QDZT::Sample::VERSION = '0.001';\E\s*$}m,
  "added version to DZT::Sample",
);

my $dzt_tp1 = $tzil->slurp_file('build/lib/DZT/TP1.pm');
like(
  $dzt_tp1,
  qr{^\s*\$\QDZT::TP1::VERSION = '0.001';\E\s*$}m,
  "added version to DZT::TP1",
);

like(
  $dzt_tp1,
  qr{^\s*\$\QDZT::TP2::VERSION = '0.001';\E\s*$}m,
  "added version to DZT::TP2",
);

my $dzt_wver = $tzil->slurp_file('build/lib/DZT/WVer.pm');
unlike(
  $dzt_wver,
  qr{^\s*\$\QDZT::WVer::VERSION = '0.001';\E\s*$}m,
  "*not* added to DZT::WVer; we have one already",
);

my $dzt_wver_two_lines = $tzil->slurp_file('build/lib/DZT/WVerTwoLines.pm');
unlike(
  $dzt_wver,
  qr{^\s*\$\QDZT::WVer::VERSION = '0.001';\E\s*$}m,
  "*not* added to DZT::WVerTwoLines; we have one already",
);

my $dzt_script_pkg = $tzil->slurp_file('build/bin/script_pkg.pl');
like(
  $dzt_script_pkg,
  qr{^\s*\$\QDZT::Script::VERSION = '0.001';\E\s*$}m,
  "added version to DZT::Script",
);

TODO: {
  local $TODO = 'only scanning for packages right now';
  my $dzt_script = $tzil->slurp_file('build/bin/script.pl');
  like(
    $dzt_script,
    qr{^\s*\$\QDZT::Script::VERSION = '0.001';\E\s*$}m,
    "added version to plain script",
  );
};

my $script_wver = $tzil->slurp_file('build/bin/script_ver.pl');
unlike(
  $script_wver,
  qr{^\s*\$\QDZT::WVer::VERSION = '0.001';\E\s*$}m,
  "*not* added to versioned DZT::Script; we have one already",
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

my $dzt_hideme = $tzil->slurp_file('build/lib/DZT/HideMe.pm');
unlike(
  $dzt_hideme,
  qr{\$DZT::TP2::VERSION},
  "no version for DZT::TP2 when it was hidden with a comment"
);

{
  local $ENV{TRIAL} = 1;

  my $tzil_trial = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini('GatherDir', 'PkgVersion', 'ExecDir'),
      },
    },
  );

  $tzil_trial->build;

  my $dzt_sample_trial = $tzil_trial->slurp_file('build/lib/DZT/Sample.pm');
  like(
    $dzt_sample_trial,
    qr{^\s*\$\QDZT::Sample::VERSION = '0.001'; # TRIAL\E\s*$}m,
    "added version with 'TRIAL' comment when \$ENV{TRIAL}=1",
  );
}

NOCRITIC: {

    # Three dists:
    # 1. nocritic = 1, trial = 0
    # 2. nocritic = 1, trial = 1
    # 3. nocritic = 0, trial = 0

    # Number 3 is the "positive control". Perl::Critic *should*
    # complain about it.

    my $nocritic_src = '
package DZT::NoCritic;
use strict;
1;
';

    my $nocritic_trial_src = '
package DZT::NoCriticTrial;
use strict;
1;
';

    my $yescritic_src = '
package DZT::YesCritic;
use strict;
1;
';

    my $tzil_nocritic = Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/lib/DZT/NoCritic.pm' => $nocritic_src,
                'source/dist.ini' => simple_ini(
                    'GatherDir', 'ExecDir',
                    ['PkgVersion' => {
                        no_critic => 1,
                    }]
                ),
            },
        },
    );

    my $tzil_nocritic_trial = do {
        local $ENV{TRIAL} = 1;
        Builder->from_config(
            { dist_root => 'corpus/dist/DZT' },
            {
                add_files => {
                    'source/lib/DZT/NoCriticTrial.pm' => $nocritic_trial_src,
                    'source/dist.ini' => simple_ini(
                        'GatherDir', 'ExecDir',
                        ['PkgVersion' => {
                            no_critic => 1,
                        }]
                    ),
                },
            },
        );
    };

    my $tzil_yescritic = Builder->from_config(
                { dist_root => 'corpus/dist/DZT' },
                {
                    add_files => {
                        'source/lib/DZT/YesCritic.pm' => $yescritic_src,
                        'source/dist.ini' => simple_ini(
                            'GatherDir', 'ExecDir',
                            ['PkgVersion' => {
                                no_critic => 0,
                            }]
                        ),
                    },
                },
            );

    $tzil_nocritic->build;
    $tzil_nocritic_trial->build;

    my $nocritic_built = $tzil_nocritic->slurp_file('build/lib/DZT/NoCritic.pm');
    my $nocritic_trial_built = $tzil_nocritic_trial->slurp_file('build/lib/DZT/NoCriticTrial.pm');

    like(
        $nocritic_built,
        qr{^\s*\$\QDZT::NoCritic::VERSION = '0.001'; ## no critic\E\s*$}m,
        "added version with 'no critic' comment when no_critic=1",
    );

    like(
        $nocritic_trial_built,
        qr{^\s*\Q## no critic\E\s*?\n\s*\$\QDZT::NoCriticTrial::VERSION = '0.001'; # TRIAL\E\s*?\n\s*\Q## use critic\E\s*$}m,
        "added version with 'TRIAL' comment and surrounding 'no critic'/'use critic' comments when no_critic=1 and \$ENV{TRIAL}=1",
    );

  SKIP:
    {
        eval { require Perl::Critic };
        skip "Perl::Critic not installed, skipping stricture criticism tests", 3 if $@;

        $tzil_yescritic->build;
        my $yescritic_built = $tzil_yescritic->slurp_file('build/lib/DZT/YesCritic.pm');

        my $critic = Perl::Critic->new();

        my @violations_yescritic = $critic->critique(\$yescritic_built);
        cmp_ok(scalar @violations_yescritic, '>', 0, "Perl::Critic complains about unprotected version declaration.");

        my @violations_nocritic = $critic->critique(\$nocritic_built);
        # Should have zero violations
        cmp_ok(scalar @violations_nocritic, '==', 0, "Perl::Critic does not complain about critic-protected version declaration.");

        my @violations_trial = $critic->critique(\$nocritic_trial_built);
        # Should have zero violations
        cmp_ok(scalar @violations_trial, '==', 0, "Perl::Critic does not complain about critic-protected trial version declaration.");
    }
}

done_testing;
