package Dist::Zilla::Role::FileMunger;
# ABSTRACT: something that alters a file's destination or content
use Moose::Role;
use Moose::Autobox;

with 'Dist::Zilla::Role::Plugin';
requires 'munge_file';

sub munge_files {
  my ($self) = @_;

  $self->munge_file($_) for $self->zilla->files->flatten;
}
    

no Moose::Role;
1;
