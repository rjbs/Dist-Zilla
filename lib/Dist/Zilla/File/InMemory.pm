package Dist::Zilla::File::InMemory;
# ABSTRACT: a file that you build entirely in memory
use Moose;
with 'Dist::Zilla::Role::File';

has content => (
  is  => 'rw',
  isa => 'Str',
  required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;
