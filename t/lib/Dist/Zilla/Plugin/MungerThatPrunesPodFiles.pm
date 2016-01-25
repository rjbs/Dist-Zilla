package Dist::Zilla::Plugin::MungerThatPrunesPodFiles;

use Moose;
with(
  'Dist::Zilla::Role::FileMunger',
);

sub munge_file {
   my ( $self, $file ) = @_;
   return unless $file->name =~ m/\.pod$/;
   
   $self->zilla->prune_file($file);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
