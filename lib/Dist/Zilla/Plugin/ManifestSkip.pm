package Dist::Zilla::Plugin::ManifestSkip;
# ABSTRACT: decline to build files that appear in a MANIFEST.SKIP-like file
use Moose;
with 'Dist::Zilla::Role::FilePruner';

use namespace::autoclean;

use ExtUtils::Manifest 1.54; # public maniskip routine
use Moose::Autobox;

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

  my $skipfile = $self->zilla->root->file( $self->skipfile );
  return unless -f $skipfile;
  my $skip = ExtUtils::Manifest::maniskip($skipfile);

  for my $file ($self->zilla->files->flatten) {
    next unless $skip->($file->name);

    $self->log_debug([ 'pruning %s', $file->name ]);

    $self->zilla->prune_file($file);
  }

  return;
}

__PACKAGE__->meta->make_immutable;
1;
