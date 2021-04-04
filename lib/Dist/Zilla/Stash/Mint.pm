package Dist::Zilla::Stash::Mint;
# ABSTRACT: a stash of your default minting provider/profile

use Moose;
with 'Dist::Zilla::Role::Stash';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

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
