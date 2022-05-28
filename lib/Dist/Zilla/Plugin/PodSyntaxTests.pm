package Dist::Zilla::Plugin::PodSyntaxTests;
# ABSTRACT: a author test for Pod syntax

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::PrereqSource';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

=head1 SYNTAX

    # Add this to your dist.ini.
    [PodSyntaxTests]

    # To test for POD validity, run this in the shell:
    $ dzil test --release

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following files:

  xt/author/pod-syntax.t   - a standard Test::Pod test

L<Test::Pod> C<1.41> will be added as a C<develop requires> dependency.

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
    'Test::Pod' => '1.41',
  );
}


__PACKAGE__->meta->make_immutable;
1;

__DATA__
___[ xt/author/pod-syntax.t ]___
#!perl
# This file was automatically generated by Dist::Zilla::Plugin::PodSyntaxTests.
use strict; use warnings;
use Test::More;
use Test::Pod 1.41;

all_pod_files_ok();
