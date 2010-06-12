package Dist::Zilla::Stash::User;
use Moose;
with 'Dist::Zilla::Role::Stash';
# ABSTRACT: a stash of user name and email

has name => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has email => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

1;
