package Dist::Zilla::Stash::User;
use Moose;
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

sub authors {
  my ($self) = @_;
  return [ sprintf "%s <%s>", $self->name, $self->email ];
}

with 'Dist::Zilla::Role::Stash::Authors';
1;
