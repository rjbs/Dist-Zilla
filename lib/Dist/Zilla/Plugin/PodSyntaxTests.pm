package Dist::Zilla::Plugin::PodSyntaxTests;
# ABSTRACT: a release test for Pod syntax
use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following files:

  xt/release/pod-syntax.t   - a standard Test::Pod test

=cut

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__DATA__
___[ xt/release/pod-syntax.t ]___
#!perl
use Test::More;

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

all_pod_files_ok();
