package Dist::Zilla::Plugin::MetaTests;
# ABSTRACT: common extra tests for META.yml
use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::PrereqSource';

use namespace::autoclean;

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following files:

  xt/release/meta-yaml.t - a standard Test::CPAN::Meta test

Note that this test doesn't actually do anything unless you have
L<Test::CPAN::Meta> installed.

=head1 SEE ALSO

Core Dist::Zilla plugins:
L<MetaResources|Dist::Zilla::Plugin::MetaResources>,
L<MetaNoIndex|Dist::Zilla::Plugin::MetaNoIndex>,
L<MetaYAML|Dist::Zilla::Plugin::MetaYAML>,
L<MetaJSON|Dist::Zilla::Plugin::MetaJSON>,
L<MetaConfig|Dist::Zilla::Plugin::MetaConfig>.

=cut

# Register the release test prereq as a "develop requires"
# so it will be listed in "dzil listdeps --author"
sub register_prereqs {
  my ($self) = @_;

  $self->zilla->register_prereqs(
    {
      phase => 'develop', type  => 'requires',
    },
    'Test::CPAN::Meta'     => 0,
  );
}

__PACKAGE__->meta->make_immutable;
1;

__DATA__
___[ xt/release/distmeta.t ]___
#!perl

use Test::More;

eval "use Test::CPAN::Meta";
plan skip_all => "Test::CPAN::Meta required for testing META.yml" if $@;
meta_yaml_ok();
