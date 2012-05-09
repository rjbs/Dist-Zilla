package Dist::Zilla::Plugin::MetaTests;
# ABSTRACT: common extra tests for META.yml
use Moose;
use Moose::Autobox;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::FilePruner';

use namespace::autoclean;

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file if F<META.yml> is in your dist:

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

sub prune_files {
    my $self = shift;

    # Bail if we find META.yml
    my $METAyml = 'META.yml';
    foreach my $file ($self->zilla->files->flatten) {
        return if $file->name eq $METAyml;
    }

    # If META.yml wasn't found, then prune out the test
    my $test_filename = 'xt/release/distmeta.t';
    foreach my $file ($self->zilla->files->flatten) {
        next unless $file->name eq $test_filename;

        $self->zilla->prune_file($file);
        $self->log_debug([ '%s not found; pruning %s', $METAyml, $file->name ]);
    }
    return;
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
