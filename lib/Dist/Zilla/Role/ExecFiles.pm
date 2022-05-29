package Dist::Zilla::Role::ExecFiles;
# ABSTRACT: something that finds files to install as executables

use Moose::Role;
with 'Dist::Zilla::Role::FileFinder';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

requires 'dir';

sub find_files ($self) {
  my $dir = $self->dir;
  my $files = [
    grep { index($_->name, "$dir/") == 0 }
      @{ $self->zilla->files }
  ];
}

1;
