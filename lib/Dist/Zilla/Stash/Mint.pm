package Dist::Zilla::Stash::Mint;
# ABSTRACT: a stash of your default minting provider/profile

use Moose;
with 'Dist::Zilla::Role::Stash';

use namespace::autoclean;

has provider => (
  is  => 'ro',
  isa => 'Str',
  required => 0,
  default => 'Default',
);

has profile => (
  is  => 'ro',
  isa => 'Str',
  required => 0,
  default => 'default',
);

__PACKAGE__->meta->make_immutable;
1;
