use strict;
use warnings;
use Test::More 0.88;

use autodie;
use Test::DZil;

my $with_version = '
package DZT::WVer;
our $VERSION = 1.234;
1;
';

my $with_version_two_lines = '
package DZT::WVerTwoLines;
our $VERSION;
$VERSION = 1.234;
1;
';

my $with_version_fully_qualified = '
package DZT::WVerFullyQualified;
$DZT::WVerFullyQualified::VERSION = 1.234;
1;
';

my $in_a_string_escaped = '
package DZT::WStrEscaped;
print "\$VERSION = 1.234;"
1;
';

my $xsloader_version = '
package DZT::XSLoader;
use XSLoader;
XSLoader::load __PACKAGE__, $DZT::XSLoader::VERSION;
1;
';

my $in_comment = '
package DZT::WInComment;
# our $VERSION = 1.234;
1;
';

my $in_comment_in_sub = '
package DZT::WInCommentInSub;
sub foo {
    # our $VERSION = 1.234;
}
1;
';

my $in_pod_stm = '
package DZT::WInPODStm;

1;

END
our $VERSION = 1.234;
=for bug

  # Because we have an END up there PPI considers this a statement

  our $VERSION = 1.234;

=cut
';  $in_pod_stm =~ s/END/__END__/g;

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

my $pod_with_pkg = '
package DZT::PodWithPackage;
=pod

=cut
';

my $pod_no_pkg = '
=pod

=cut
';

my $tzil = Builder->from_config(
  { dist_root => 'corpus/dist/DZT' },
  {
    add_files => {
      'source/lib/DZT/TP1.pm'    => $two_packages,
      'source/lib/DZT/WVer.pm'   => $with_version,
      'source/lib/DZT/WVerTwoLines.pm' => $with_version_two_lines,
      'source/lib/DZT/WVerFullyQualified.pm' => $with_version_fully_qualified,
      'source/lib/DZT/WStrEscaped.pm'  => $in_a_string_escaped,
      'source/lib/DZT/XSLoader.pm'  => $xsloader_version,
      'source/lib/DZT/WInComment.pm' => $in_comment,
      'source/lib/DZT/WInCommentInSub.pm' => $in_comment_in_sub,
      'source/lib/DZT/WInPODStm.pm' => $in_pod_stm,
      'source/lib/DZT/R1.pm'     => $repeated_packages,
      'source/lib/DZT/Monkey.pm' => $monkey_patched,
      'source/lib/DZT/HideMe.pm' => $hide_me_comment,
      'source/lib/DZT/PodWithPackage.pm' => $pod_with_pkg,
      'source/lib/DZT/PodNoPackage.pm' => $pod_no_pkg,
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
  $dzt_wver_two_lines,
  qr{^\s*\$\QDZT::WVerTwoLines::VERSION = '0.001';\E\s*$}m,
  "*not* added to DZT::WVerTwoLines; we have one already",
);

my $dzt_wver_fully_qualified = $tzil->slurp_file('build/lib/DZT/WVerFullyQualified.pm');
unlike(
  $dzt_wver_fully_qualified,
  qr{^\s*\$\QDZT::WVerFullyQualified::VERSION = '0.001';\E\s*$}m,
  "*not* added to DZT::WVer; we have one already",
);

my $dzt_xsloader = $tzil->slurp_file('build/lib/DZT/XSLoader.pm');
like(
  $dzt_xsloader,
  qr{^\s*\$\QDZT::XSLoader::VERSION = '0.001';\E\s*$}m,
  "added version to DZT::XSLoader",
);

my $dzt_wver_in_comment = $tzil->slurp_file('build/lib/DZT/WInComment.pm');
like(
  $dzt_wver_in_comment,
  qr{^\s*\$\QDZT::WInComment::VERSION = '0.001';\E\s*$}m,
  "added to DZT::WInComment; the one we have is in a comment",
);

my $dzt_wver_in_comment_in_sub = $tzil->slurp_file('build/lib/DZT/WInCommentInSub.pm');
like(
  $dzt_wver_in_comment_in_sub,
  qr{^\s*\$\QDZT::WInCommentInSub::VERSION = '0.001';\E\s*$}m,
  "added to DZT::WInCommentInSub; the one we have is in a comment",
);

my $dzt_wver_in_pod_stm = $tzil->slurp_file('build/lib/DZT/WInPODStm.pm');
like(
  $dzt_wver_in_pod_stm,
  qr{^\s*\$\QDZT::WInPODStm::VERSION = '0.001';\E\s*$}m,
  "added to DZT::WInPODStm; the one we have is in some POD",
);

my $dzt_wver_str_escaped = $tzil->slurp_file('build/lib/DZT/WStrEscaped.pm');
like(
  $dzt_wver_str_escaped,
  qr{^\s*\$\QDZT::WStrEscaped::VERSION = '0.001';\E\s*$}m,
  "added to DZT::WStrEscaped; the one we have is escaped",
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

my $dzt_podwithpackage = $tzil->slurp_file('build/lib/DZT/PodWithPackage.pm');
like(
  $dzt_podwithpackage,
  qr{^\s*\$\QDZT::PodWithPackage::VERSION = '0.001';\E\s*$}m,
  "added version to DZT::PodWithPackage",
);

my $dzt_podnopackage = $tzil->slurp_file('build/lib/DZT/PodNoPackage.pm');
unlike(
  $dzt_podnopackage,
  qr{VERSION},
  "no version for pod files with no package declaration"
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
  my $assignments = () = $dzt_sample_trial =~ /(DZT::Sample::VERSION =)/g;

  is($assignments, 1, "we only add 1 VERSION assignment");

  like(
    $dzt_sample_trial,
    qr{^\s*\$\QDZT::Sample::VERSION = '0.001'; # TRIAL\E\s*$}m,
    "added version with 'TRIAL' comment when \$ENV{TRIAL}=1",
  );
}

my $two_packages_weird = <<'END';
package DZT::TPW1;

{package DZT::TPW2;

sub tmp}
END

my $tzil2 = Builder->from_config(
  { dist_root => 'corpus/dist/DZT' },
  {
    add_files => {
      'source/lib/DZT/TPW.pm'    => $two_packages_weird,
      'source/dist.ini' => simple_ini('GatherDir', 'PkgVersion', 'ExecDir'),
    },
  },
);
$tzil2->plugins->[1]->{die_on_line_insertion} = 1;
$tzil2->plugins->[1]->{use_our} = 1;
$tzil2->build;

my $dzt_tpw = $tzil2->slurp_file('build/lib/DZT/TPW.pm');
like(
  $dzt_tpw,
  qr{^\s*\{ our \$VERSION = '0\.001'; \}\s*$}m,
  "added 'our' version to DZT::TPW1",
);

like(
  $dzt_tpw,
  qr{^\s*\{ our \$VERSION = '0\.001'; \}\s*$}m,
  "added 'our' version to DZT::TPW2",
);

done_testing;

