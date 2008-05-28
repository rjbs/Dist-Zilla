package Dist::Zilla::Role::File;
use Moose::Role;

has name => (
  is   => 'rw',
  isa  => 'Str', # Path::Class::File?
  required => 1,
);

# requires 'content';

no Moose::Role;
1;
