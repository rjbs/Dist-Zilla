package Dist::Zilla::Plugin::ManifestSkip;
# ABSTRACT: decline to build files that appear in a MANIFEST.SKIP-like file
use Moose;
with 'Dist::Zilla::Role::FilePruner';

use ExtUtils::Manifest;

has skipfile => (is => 'ro', required => 1, default => 'MANIFEST.SKIP');

sub prune_files {
  my ($self) = @_;

  # XXX: Totally evil.  Just mucking about. -- rjbs, 2008-05-27
  # Randy Kobes has accepted a patch to make maniskip non-private. -- rjbs,
  # 2008-06-02
  my $skip = ExtUtils::Manifest::_maniskip;

  my $files = $self->zilla->files;
  @$files = grep { ! $skip->($_->name) } @$files;

  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
