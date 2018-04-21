package Dist::Zilla::Stash::User;
# ABSTRACT: a stash of user name and email

use Moose;

use Dist::Zilla::Dialect;

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

sub authors ($self) {
  my $string = sprintf "%s <%s>", $self->name, $self->email;
  return $string if wantarray;

  state %warned;

  my ($package, $pmfile, $line) = caller;
  Carp::carp('in v7, $zilla->authors should only be called in list context; scalar context behavior will change in Dist::Zilla v8')
    unless $warned{ $pmfile, $line }++;

  return [ $string ];
}

with 'Dist::Zilla::Role::Stash::Authors';
__PACKAGE__->meta->make_immutable;
1;
