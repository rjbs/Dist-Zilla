use strict;
use warnings;
use Test::More 0.88;
use Test::Deep;

use autodie;
use Test::DZil;

my $tzil = Builder->from_config(
  { dist_root => 'corpus/dist/DZT' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        qw(GatherDir MetaTests PodSyntaxTests PodCoverageTests)
      ),
    },
  },
);

$tzil->build;

my $meta_test = $tzil->slurp_file('build/xt/author/distmeta.t');
like($meta_test, qr{meta_yaml_ok}, "we have a distmeta file that tests it");

my $pod_test = $tzil->slurp_file('build/xt/author/pod-syntax.t');
like($pod_test, qr{all_pod_files_ok}, "we have a pod-syntax test");

my $pod_c_test = $tzil->slurp_file('build/xt/author/pod-coverage.t');
like($pod_c_test, qr{all_pod_coverage_ok}, "we have a pod-coverage test");

cmp_deeply(
  $tzil->distmeta,
  superhashof(
    {
      prereqs =>
      {
        develop =>
        {
          requires =>
          {
            # PodSyntaxTests
            'Test::Pod' => '1.41',
            # PodCoverageTests
            'Test::Pod::Coverage'     => '1.08',
            'Pod::Coverage::TrustPod' => 0,
            # MetaTests
            'Test::CPAN::Meta' => 0,
          },
        },
      },
    }
  ),
  'develop prereqs'
);

done_testing;
