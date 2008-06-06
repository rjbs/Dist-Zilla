package Dist::Zilla::Role::FileGatherer;
use Moose::Autobox;
# ABSTRACT: something that gathers files into the distribution
use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'gather_files';

sub add_file {
  my ($self, $file) = @_;
  my ($pkg, undef, $line) = caller;

  $file->meta->get_attribute('added_by')->set_value($file, "$pkg line $line");
  $self->zilla->files->push($file);
}

no Moose::Role;
1;
