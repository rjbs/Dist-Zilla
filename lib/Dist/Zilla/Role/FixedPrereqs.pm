package Dist::Zilla::Role::FixedPrereqs;
# ABSTRACT: enumerate fixed (non-conditional) prerequisites
use Moose::Role;

=head1 DESCRIPTION

FixedPrereqs plugins have a C<prereq> method that should return a hashref of
prerequisite package names and versions, indicating unconditional prerequisites
to be merged together.

=cut

with 'Dist::Zilla::Role::Plugin';
requires 'prereq';

sub __from_name {
  my ($self) = @_;
  my $name = $self->plugin_name;

  # such as C<configure>, C<build>, C<test> and C<runtime>.  Values are
  # relationship such as C<requires>, C<prefers>, or C<recommends>.  The

  my ($phase, $type) = $name =~ /\A
    (Build|Test|Runtime|Configure)
    (Requires|Prefers|Recommends)
  \z/x;

  return ($phase, $type);
}

has prereq_phase => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  init_arg => 'phase',
  default  => sub {
    my ($self) = @_;
    my ($phase, $type) = $self->__from_name;
    $phase ||= 'runtime';
    $phase = lc $phase;
    $phase = 'build' if $phase eq 'test'; # XXX: Temporary -- rjbs, 2010-03-20
    return $phase;
  },
);

has prereq_type => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  init_arg => 'type',
  default  => sub {
    my ($self) = @_;
    my ($phase, $type) = $self->__from_name;
    $type ||= 'requires';
    $type = lc $type;
    return $type;
  },
);


no Moose::Role;
1;
