package Dist::Zilla::Plugin::PruneFiles;
# ABSTRACT: prune arbirary files from the dist
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FilePruner';

sub multivalue_args { qw(file) }

has filenames => (
  is   => 'ro',
  isa  => 'ArrayRef',
  lazy => 1,
  init_arg => 'file',
  default  => sub { [] },
);

sub prune_files {
  my ($self) = @_;

  my $files = $self->zilla->files;
  my $any = $self->filenames->any;

  @$files = $files->grep(sub { $_->name ne $any })->flatten;

  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
