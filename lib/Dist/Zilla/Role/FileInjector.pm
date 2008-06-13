package Dist::Zilla::Role::FileInjector;
use Moose::Autobox;
# ABSTRACT: something that can add files to the distribution
use Moose::Role;

=head1 DESCRIPTION

This role should be implemented by any plugin that plans to add files into the
distribution.  It provides one method (C<L</add_file>>, documented below),
which adds a file to the distribution, noting the place of addition.

=method add_file

  $plugin->add_file($dzil_file);

This adds a file to the distribution, setting the file's C<added_by> attribute
as it does so.

=cut

sub add_file {
  my ($self, $file) = @_;
  my ($pkg, undef, $line) = caller;

  $file->meta->get_attribute('added_by')->set_value($file, "$pkg line $line");
  # $self->log($file->name . " added by $pkg");
  $self->zilla->files->push($file);
}

no Moose::Role;
1;
