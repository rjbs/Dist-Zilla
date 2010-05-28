package Dist::Zilla::MVP::Assembler::Zilla;
use Moose;
extends 'Dist::Zilla::MVP::Assembler';
# ABSTRACT: Dist::Zilla::MVP::Assembler for the Dist::Zilla object

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

sub zilla {
  my ($self) = @_;
  $self->sequence->section_named('_')->zilla;
}

no Moose;
1;
