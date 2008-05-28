package Dist::Zilla::File::InMemory;
use Moose;
with 'Dist::Zilla::Role::File';

has content => (
  is  => 'rw',
  isa => 'Str',
  required => 1,
);

no Moose;
1;
