package Dist::Zilla::Stash::Generic;
use Moose;
with 'Dist::Zilla::Role::Stash';
# ABSTRACT: a stash that just does named value lookup

has payload => (
  is  => 'ro',
  isa => 'HashRef',
  required => 1,
);

sub value {
  my ($self, $name) = @_;
  $self->payload->{ $name };
}

sub stash_from_config {
  my ($class, $name, $arg, $section) = @_;

  my $self = $class->new({ payload => $arg });
  return $self;
}

1;
