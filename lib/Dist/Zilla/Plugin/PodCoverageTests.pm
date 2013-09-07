package Dist::Zilla::Plugin::PodCoverageTests;
# ABSTRACT: a release test for Pod coverage
use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::PrereqSource';

use namespace::autoclean;

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following files:

  xt/release/pod-coverage.t - a standard Test::Pod::Coverage test

This test uses L<Pod::Coverage::TrustPod> to check your Pod coverage.  This
means that to indicate that some subs should be treated as covered, even if no
documentation can be found, you can add:

  =for Pod::Coverage sub_name other_sub this_one_too

=cut

# Register the release test prereq as a "develop requires"
# so it will be listed in "dzil listdeps --author"
sub register_prereqs {
  my ($self) = @_;

  $self->zilla->register_prereqs(
    {
      type  => 'requires',
      phase => 'develop',
    },
    'Test::Pod::Coverage'     => '1.08',
    'Pod::Coverage::TrustPod' => 0,
  );
}

__PACKAGE__->meta->make_immutable;
1;

__DATA__
___[ xt/release/pod-coverage.t ]___
#!perl

use Test::Pod::Coverage 1.08;
use Pod::Coverage::TrustPod;

all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::TrustPod' });
