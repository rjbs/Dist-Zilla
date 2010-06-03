package Dist::Zilla::Stash::Heap;
use Moose;
with 'Dist::Zilla::Role::Stash';
# ABSTRACT: a stash that's just a big heap of names and values

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
