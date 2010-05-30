package Dist::Zilla::MVP::Assembler::GlobalConfig;
use Moose;
extends 'Dist::Zilla::MVP::Assembler';
# ABSTRACT: Dist::Zilla::MVP::Assembler for global configuration

has stash => (
  is  => 'ro',
  isa => 'HashRef[Object]',
  default => sub { {} },
);

sub register_stash_entry {
  my ($self, $name, $object) = @_;

  $self->log_fatal("tried to register $name stash entry twice")
    if $self->stash->{ $name };

  $self->stash->{ $name } = $object;
  return;
}

no Moose;
1;
