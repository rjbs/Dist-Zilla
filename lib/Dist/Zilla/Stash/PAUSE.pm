package Dist::Zilla::Stash::PAUSE;
use Moose;
# ABSTRACT: a stash of your PAUSE credentials

sub mvp_aliases {
  return { user => 'username' };
}

has username => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has password => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

with 'Dist::Zilla::Role::Stash::Login';
1;
