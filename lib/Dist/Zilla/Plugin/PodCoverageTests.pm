package Dist::Zilla::Plugin::PodCoverageTests;
# ABSTRACT: a release test for Pod coverage
use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following files:

  xt/release/pod-coverage.t - a standard Test::Pod::Coverage test

=cut

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__DATA__
___[ xt/release/pod-coverage.t ]___
#!perl

use Test::More;

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
  if $@;

eval "use Pod::Coverage::TrustPod";
plan skip_all => "Pod::Coverage::TrustPod required for testing POD coverage"
  if $@;

all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::TrustPod' });
