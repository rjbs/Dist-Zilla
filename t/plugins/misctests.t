use strict;
use warnings;
use Test::More 0.88 tests => 2;

use lib 't/lib';

use autodie;
use Test::DZil;
use Moose::Autobox;

subtest 'No META.yml' => sub {
  plan tests => 3;
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

  my $has_distmeta_test = grep( $_->name eq 'xt/release/distmeta.t', $tzil->files->flatten);
  ok(!$has_distmeta_test, 'distmeta.t was pruned out');

  my $pod_test = $tzil->slurp_file('build/xt/release/pod-syntax.t');
  like($pod_test, qr{all_pod_files_ok}, "we have a pod-syntax test");

  my $pod_c_test = $tzil->slurp_file('build/xt/release/pod-coverage.t');
  like($pod_c_test, qr{all_pod_coverage_ok}, "we have a pod-coverage test");
};

subtest 'META.yml' => sub {
  plan tests => 3;
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          qw(MetaYAML GatherDir MetaTests PodSyntaxTests PodCoverageTests)
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
};
