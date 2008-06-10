package Dist::Zilla::Plugin::InlineFiles;
# ABSTRACT: files in a data section
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

=head1 DESCRIPTION

This plugin exists only to be extended, and gathers all files contained in its
data section and those of its ancestors.  For more information, see
L<Data::Section|Data::Section>.

=cut

use Data::Section -setup;
use Dist::Zilla::File::InMemory;

sub gather_files {
  my ($self) = @_;

  my $data = $self->merged_section_data;
  return unless $data and %$data;

  for my $name (keys %$data) {
    $self->add_file(
      Dist::Zilla::File::InMemory->new({
        name    => $name,
        content => ${ $data->{$name} },
      }),
    );
  }

  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
