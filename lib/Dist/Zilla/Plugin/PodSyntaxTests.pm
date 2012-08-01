package Dist::Zilla::Plugin::PodSyntaxTests;
# ABSTRACT: a release test for Pod syntax
use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';

use namespace::autoclean;

=head1 SYNTAX

    # Add this to your dist.ini.
    [PodSyntaxTests]

    # To test for POD validity, run this in the shell:
    $ dzil test --release

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following files:

  xt/release/pod-syntax.t   - a standard Test::Pod test

One can run the release tests by invoking C<dzil test --release>.

=cut

__PACKAGE__->meta->make_immutable;
1;

__DATA__
___[ xt/release/pod-syntax.t ]___
#!perl
use Test::More;

eval "use Test::Pod 1.41";
plan skip_all => "Test::Pod 1.41 required for testing POD" if $@;

all_pod_files_ok();
