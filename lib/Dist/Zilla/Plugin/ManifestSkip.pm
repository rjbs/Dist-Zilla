package Dist::Zilla::Plugin::ManifestSkip;
use Moose;
with 'Dist::Zilla::Role::FilePruner';

use ExtUtils::Manifest;

has skipfile => (is => 'ro', required => 1, default => 'MANIFEST.SKIP');

sub prune_files {
  my ($self, $files) = @_;

  # XXX: Totally evil.  Just mucking about. -- rjbs, 2008-05-27
  # Randy Kobes has accepted a patch to make maniskip non-private. -- rjbs,
  # 2008-06-02
  my $skip = ExtUtils::Manifest::_maniskip;

  @$files = grep { ! $skip->($_->name) } @$files;

  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
