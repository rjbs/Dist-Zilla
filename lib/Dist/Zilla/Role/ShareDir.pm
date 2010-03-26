package Dist::Zilla::Role::ShareDir;
use Moose::Role;
with 'Dist::Zilla::Role::FileFinder';
# ABSTRACT: something that picks a directory to install as shared files

sub find_files {
  my ($self) = @_;

  my $dir = $self->dir;
  my $files = $self->zilla->files->grep(sub { index($_->name, "$dir/") == 0 });
}

1;
