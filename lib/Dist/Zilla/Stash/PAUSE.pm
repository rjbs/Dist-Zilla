package Dist::Zilla::Stash::PAUSE;
use Moose;
with 'Dist::Zilla::Role::Stash';
# ABSTRACT: a stash of your PAUSE credentials

has user => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has password => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

1;
