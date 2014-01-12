package Dist::Zilla::Stash::User;
# ABSTRACT: a stash of user name and email

use Moose;

use namespace::autoclean;

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
__PACKAGE__->meta->make_immutable;
1;
