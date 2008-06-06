package Dist::Zilla::Plugin::License;
# ABSTRACT: output a LICENSE file
use Moose;
with 'Dist::Zilla::Role::FileGatherer';

use Dist::Zilla::File::InMemory;

sub gather_files {
  my ($self, $arg) = @_;

  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'LICENSE',
    content => $self->zilla->license->fulltext,
  });

  return [ $file ];
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
