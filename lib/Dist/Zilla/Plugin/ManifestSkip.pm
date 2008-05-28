package Dist::Zilla::Plugin::ManifestSkip;
use Moose;
with 'Dist::Zilla::Role::FilePruner';

use ExtUtils::Manifest;

sub prune_files {
  my ($self, $files) = @_;

  # XXX: Totally evil.  Just mucking about. -- rjbs, 2008-05-27
  my $skip = ExtUtils::Manifest::_maniskip;
  @$files = grep { ! $skip->($_) } @$files;
  return;
}

no Moose;
1;
