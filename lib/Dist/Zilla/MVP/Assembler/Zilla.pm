package Dist::Zilla::MVP::Assembler::Zilla;
use Moose;
extends 'Dist::Zilla::MVP::Assembler';
# ABSTRACT: Dist::Zilla::MVP::Assembler for the Dist::Zilla object

=head1 OVERVIEW

This is a subclass of L<Dist::Zilla::MVP::Assembler> used when assembling the
Dist::Zilla object.

It has a C<zilla_class> attribute, which is used to determine what class of
Dist::Zilla object to create.  (This isn't very useful now, but will be in the
future when minting and building use different subclasses of Dist::Zilla.)

Upon construction, the assembler will create a L<Dist::Zilla::MVP::RootSection>
as the initial section.

=cut

use MooseX::Types::Perl qw(PackageName);
use Dist::Zilla::MVP::RootSection;

sub BUILD {
  my ($self) = @_;

  my $root = Dist::Zilla::MVP::RootSection->new;
  $self->sequence->add_section($root);
}

has zilla_class => (
  is      => 'ro',
  isa     => PackageName,
  default => 'Dist::Zilla',
);

=method zilla

This method is a shortcut for retrieving the C<zilla> from the root section.
If called before that section has been finalized, it will result in an
exception.

=cut

sub zilla {
  my ($self) = @_;
  $self->sequence->section_named('_')->zilla;
}

=method register_stash

  $assembler->register_stash($name => $stash_object);

This adds a stash to the assembler's zilla's stash registry -- unless the name
is already taken, in which case an exception is raised.

=cut

sub register_stash {
  my ($self, $name, $object) = @_;
  $self->log_fatal("tried to register $name stash entry twice")
    if $self->zilla->_local_stashes->{ $name };

  $self->zilla->_local_stashes->{ $name } = $object;
  return;
}

no Moose;
1;
