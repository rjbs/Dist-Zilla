package Dist::Zilla::Role::File;
# ABSTRACT: something that can act like a file
use Moose::Role;

has name => (
  is   => 'rw',
  isa  => 'Str', # Path::Class::File?
  required => 1,
);

has added_by => (
  is => 'ro',
);

has install_type => (
  is => 'rw',
);

# requires 'content';

no Moose::Role;
1;
