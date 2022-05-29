package Dist::Zilla::Plugin::PodCoverageTests;
# ABSTRACT: a author test for Pod coverage

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::PrereqSource';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

=head1 SYNOPSIS

    # Add this line to dist.ini
    [PodCoverageTests]

    # Run this in the command line to test for POD coverage:
    $ dzil test --release

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following files:

  xt/author/pod-coverage.t - a standard Test::Pod::Coverage test

This test uses L<Pod::Coverage::TrustPod> to check your Pod coverage.  This
means that to indicate that some subs should be treated as covered, even if no
documentation can be found, you can add:

  =for Pod::Coverage sub_name other_sub this_one_too

L<Test::Pod::Coverage> C<1.08> and L<Pod::Coverage::TrustPod> will be added as
C<develop requires> dependencies.

One can run the release tests by invoking C<dzil test --release>.

=cut

# Register the author test prereq as a "develop requires"
# so it will be listed in "dzil listdeps --author"
sub register_prereqs ($self) {
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
___[ xt/author/pod-coverage.t ]___
#!perl
# This file was automatically generated by Dist::Zilla::Plugin::PodCoverageTests.

use Test::Pod::Coverage 1.08;
use Pod::Coverage::TrustPod;

all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::TrustPod' });
