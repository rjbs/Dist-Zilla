package Dist::Zilla::Plugin::Prereq;
# ABSTRACT: list simple prerequisites
use Moose;
with 'Dist::Zilla::Role::FixedPrereqs';

=head1 SYNOPSIS

In your F<dist.ini>:

  [Prereq]
  Foo::Bar = 1.002
  MRO::Compat = 10
  Sub::Exporter = 0

=head1 DESCRIPTION

This module adds "fixed" prerequisites to your distribution.  These are prereqs
with a known, fixed minimum version that doens't change based on platform or
other conditions.

=cut

has _prereq => (
  is   => 'ro',
  isa  => 'HashRef',
  default => sub { {} },
);

sub new {
  my ($class, $arg) = @_;

  my $self = $class->SUPER::new({
    '=name' => delete $arg->{'=name'},
    zilla   => delete $arg->{zilla},
    _prereq => $arg,
  });
}

sub prereq { shift->_prereq }

no Moose;
__PACKAGE__->meta->make_immutable;
1;
