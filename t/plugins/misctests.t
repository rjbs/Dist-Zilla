use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use autodie;
use Test::DZil;

my $tzil = Builder->from_config(
  { dist_root => 'corpus/DZT' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        qw(GatherDir MetaTests PodSyntaxTests PodCoverageTests)
      ),
    },
  },
);

$tzil->build;

my $meta_test = $tzil->slurp_file('build/xt/release/distmeta.t');
like($meta_test, qr{meta_yaml_ok}, "we have a distmeta file that tests it");

my $pod_test = $tzil->slurp_file('build/xt/release/pod-syntax.t');
like($pod_test, qr{all_pod_files_ok}, "we have a pod-syntax test");

my $pod_c_test = $tzil->slurp_file('build/xt/release/pod-coverage.t');
like($pod_c_test, qr{all_pod_coverage_ok}, "we have a pod-coverage test");

done_testing;
