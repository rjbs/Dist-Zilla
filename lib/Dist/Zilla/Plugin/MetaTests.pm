package Dist::Zilla::Plugin::MetaTests;
# ABSTRACT: common extra tests for META.yml
use Moose;
use Moose::Autobox;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::FilePruner';

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file if F<META.yml> is in your dist:

  xt/release/meta-yaml.t - a standard Test::CPAN::Meta test

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
no Moose;
1;

__DATA__
___[ xt/release/distmeta.t ]___
#!perl

use Test::More;

eval "use Test::CPAN::Meta";
plan skip_all => "Test::CPAN::Meta required for testing META.yml" if $@;
meta_yaml_ok();
