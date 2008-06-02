package Dist::Zilla::Plugin::License;
use Moose;
with 'Dist::Zilla::Role::FileWriter';

use Dist::Zilla::File::InMemory;

sub write_files {
  my ($self, $arg) = @_;

  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'LICENSE',
    content => $self->zilla->license->fulltext,
  });

  return [ $file ];
}

1;
