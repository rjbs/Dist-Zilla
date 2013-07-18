use strict;
use warnings;
use Test::More 0.88;

use autodie;
use Test::DZil;

my $with_place_for_pod = '

package DZT::WPFP;

=head1 NAME

DZT::WPFP - with place for pod!

=cut

sub foo { }

1;
';

my $with_version = '

package DZT::WVer;

=head1 NAME

DZT::WVer - version in pod!

=head1 VERSION

version 1.234

=cut

sub foo { }

1;
';

my $with_multi_line_abstract = '

package DZT::MLA;

=head1 NAME

DZT::MLA - This abstract spans
multiple lines.

=cut

sub foo { }

1;
';

my $script = '
#!/usr/bin/perl

=head1 NAME

script.pl - a podded script!

=cut

print "hello world\n";
';

my $tzil = Builder->from_config(
  { dist_root => 'corpus/dist/DZT' },
  {
    add_files => {
      'source/lib/DZT/WPFP.pm' => $with_place_for_pod,
      'source/lib/DZT/WVer.pm' => $with_version,
      'source/lib/DZT/MLA.pm' => $with_multi_line_abstract,
      'source/bin/script.pl'   => $script,
      'source/dist.ini' => simple_ini('GatherDir', 'PodVersion', 'ExecDir'),
    },
  },
);

$tzil->build;

my $want = <<'END_POD';
=head1 VERSION

version 0.001

=cut
END_POD

my $want_mla = <<'END_POD';
=head1 NAME

DZT::MLA - This abstract spans
multiple lines.

=head1 VERSION

version 0.001

=cut
END_POD

my $dzt_sample = $tzil->slurp_file('build/lib/DZT/Sample.pm');
ok(
  index($dzt_sample, $want) == -1,
  "we didn't add version pod to Sample; it has no NAME",
);

my $dzt_wpfp = $tzil->slurp_file('build/lib/DZT/WPFP.pm');
ok(
  index($dzt_wpfp, $want) > 0,
  "we did add version pod to WPFP",
);

my $dzt_wver = $tzil->slurp_file('build/lib/DZT/WVer.pm');
ok(
  index($dzt_wver, $want) == -1,
  "we didn't add version pod to WVer; it has one already",
);

my $dzt_mla = $tzil->slurp_file('build/lib/DZT/MLA.pm');
ok(
  index($dzt_mla, $want_mla) > 0,
  "we properly skipped over multi-line abstract",
);

my $dzt_script = $tzil->slurp_file('build/bin/script.pl');
ok(
  index($dzt_script, $want) > 0,
  "we did add version pod to script",
);

done_testing;

