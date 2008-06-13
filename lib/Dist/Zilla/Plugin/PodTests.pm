package Dist::Zilla::Plugin::PodTests;
# ABSTRACT: common extra tests for pod
use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following files:

  xt/release/pod-coverage.t - a standard Test::Pod::Coverage test
  xt/release/pod-syntax.t   - a standard Test::Pod test

This files are only gathered if the environment variable C<RELEASE_TESTING> is
true, which is the case when running C<dzil test>.

=cut

override 'gather_files' => sub {
  my ($self) = @_;
  return unless $ENV{RELEASE_TESTING};
  super();
};

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
