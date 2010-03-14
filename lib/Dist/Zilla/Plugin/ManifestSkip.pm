package Dist::Zilla::Plugin::ManifestSkip;
# ABSTRACT: decline to build files that appear in a MANIFEST.SKIP-like file
use Moose;
with 'Dist::Zilla::Role::FilePruner';

use ExtUtils::Manifest 1.54; # public maniskip routine

=head1 DESCRIPTION

This plugin reads a MANIFEST.SKIP-like file, as used by L<ExtUtils::MakeMaker>
and L<ExtUtils::Manifest>, and prunes any files that it declares should be
skipped.

=attr skipfile

This is the name of the file to read for MANIFEST.SKIP-like content.  It
defaults, unsurprisingly, to F<MANIFEST.SKIP>.

=cut

has skipfile => (is => 'ro', required => 1, default => 'MANIFEST.SKIP');

sub prune_files {
  my ($self) = @_;

  my $skip = ExtUtils::Manifest::maniskip($self->skipfile);

  my $files = $self->zilla->files;
  @$files = grep { ! $skip->($_->name) } @$files;

  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
