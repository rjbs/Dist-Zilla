package Dist::Zilla::Plugin::PodSyntaxTests;
# ABSTRACT: a release test for Pod syntax
use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::PrereqSource';

use namespace::autoclean;

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following files:

  xt/release/pod-syntax.t   - a standard Test::Pod test

L<Test::Pod> C<1.41> will be added as a C<develop requires> dependency.

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
    'Test::Pod' => '1.41',
  );
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__
___[ xt/release/pod-syntax.t ]___
#!perl

use Test::Pod 1.41;

all_pod_files_ok();
