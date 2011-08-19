package Dist::Zilla::MVP::Assembler::GlobalConfig;
use Moose;
extends 'Dist::Zilla::MVP::Assembler';
# ABSTRACT: Dist::Zilla::MVP::Assembler for global configuration

use namespace::autoclean;

=head1 OVERVIEW

This is a subclass of L<Dist::Zilla::MVP::Assembler> used when assembling the
global configuration.  It has a C<stash_registry> attribute, a hashref, into
which stashes will be registered.

They get registered via the C<register_stash> method, below, generally called
by the C<register_component> method on L<Dist::Zilla::Role::Stash>-performing
class.

=cut

has stash_registry => (
  is  => 'ro',
  isa => 'HashRef[Object]',
  default => sub { {} },
);

=method register_stash

  $assembler->register_stash($name => $stash_object);

This adds a stash to the assembler's stash registry -- unless the name is
already taken, in which case an exception is raised.

=cut

sub register_stash {
  my ($self, $name, $object) = @_;

  # $self->log_fatal("tried to register $name stash entry twice")
  confess("tried to register $name stash entry twice")
    if $self->stash_registry->{ $name };

  $self->stash_registry->{ $name } = $object;
  return;
}

__PACKAGE__->meta->make_immutable;
1;
