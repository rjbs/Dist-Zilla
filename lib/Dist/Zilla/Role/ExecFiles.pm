package Dist::Zilla::Role::ExecFiles;
# ABSTRACT: something that finds files to install as executables

use Moose::Role;
with 'Dist::Zilla::Role::FileFinder';

use Dist::Zilla::Dialect;

use namespace::autoclean;

requires 'dir';

sub find_files {
  my ($self) = @_;

  my $dir = $self->dir;
  return [ grep { index($_->name, "$dir/") == 0 } $self->zilla->files->@* ];
}

1;
