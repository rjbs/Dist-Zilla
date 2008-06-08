package Dist::Zilla::Role::FileInjector;
use Moose::Autobox;
# ABSTRACT: something that can add files to the distribution
use Moose::Role;

sub add_file {
  my ($self, $file) = @_;
  my ($pkg, undef, $line) = caller;

  $file->meta->get_attribute('added_by')->set_value($file, "$pkg line $line");
  $self->zilla->files->push($file);
}

no Moose::Role;
1;
