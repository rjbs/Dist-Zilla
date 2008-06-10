package Dist::Zilla::Plugin::ManifestSkip;
# ABSTRACT: decline to build files that appear in a MANIFEST.SKIP-like file
use Moose;
with 'Dist::Zilla::Role::FilePruner';

use ExtUtils::Manifest;

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
