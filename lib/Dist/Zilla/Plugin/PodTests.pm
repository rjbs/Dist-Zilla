package Dist::Zilla::Plugin::PodTests;
# ABSTRACT: common extra tests for pod
use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__DATA__
___[ xt/release/pod-coverage.t ]___
#!perl -T

use Test::More;

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
  if $@;

eval "use Pod::Coverage::TrustPod";
plan skip_all => "Pod::Coverage::TrustPod required for testing POD coverage"
  if $@;

all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::TrustPod' });

___[ xt/release/pod-syntax.t ]___
#!perl -T
use Test::More;

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

all_pod_files_ok();
