package Dist::Zilla::Plugin::InlineFiles;
# ABSTRACT: files in a data section
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

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
__DATA__
