package Dist::Zilla::Plugin::MetaTests;
# ABSTRACT: common extra tests for META.yml
use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following files:

    xt/release/meta-yaml.t - a standard Test::CPAN::Meta test

This file is only gathered if the environment variable C<RELEASE_TESTING> is
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
___[ xt/release/meta-yaml.t ]___
#!perl -T

use Test::More;

eval "use Test::CPAN::Meta";
plan skip_all => "Test::CPAN::Meta required for testing META.yml" if $@;
meta_yaml_ok();
