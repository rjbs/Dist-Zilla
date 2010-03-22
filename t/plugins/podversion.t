use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

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

my $tzil = Dist::Zilla::Tester->from_config(
  { dist_root => 'corpus/DZT' },
  {
    add_files => {
      'source/lib/DZT/WPFP.pm' => $with_place_for_pod,
      'source/lib/DZT/WVer.pm' => $with_version,
      'source/dist.ini' => simple_ini('GatherDir', 'PodVersion'),
    },
  },
);

$tzil->build;

my $want = <<'END_POD';
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

done_testing;

