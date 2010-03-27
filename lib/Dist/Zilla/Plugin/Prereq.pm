package Dist::Zilla::Plugin::Prereq;
# ABSTRACT: list simple prerequisites
use Moose;
with 'Dist::Zilla::Role::PrereqSource';

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

around dump_config => sub {
  my ($orig, $self) = @_;
  my $config = $self->$orig;

  my $this_config = {
    type  => $self->prereq_type,
    phase => $self->prereq_phase,
  };

  $config->{'' . __PACKAGE__} = $this_config;

  return $config;
};

has _prereq => (
  is   => 'ro',
  isa  => 'HashRef',
  default => sub { {} },
);

sub BUILDARGS {
  my ($class, @arg) = @_;
  my %copy = ref $arg[0] ? %{$arg[0]} : @arg;

  my $zilla = delete $copy{zilla};
  my $name  = delete $copy{plugin_name};

  my @dashed = grep { /^-/ } keys %copy;

  my %other;
  for my $dkey (@dashed) {
    (my $key = $dkey) =~ s/^-//;

    $other{ $key } = delete $copy{ $dkey };
  }

  confess "don't try to pass -_prereq as a build arg!" if $other{_prereq};

  return {
    zilla => $zilla,
    plugin_name => $name,
    _prereq     => \%copy,
    %other,
  }
}

sub register_prereqs {
  my ($self) = @_;

  $self->zilla->register_prereqs(
    {
      type  => $self->prereq_type,
      phase => $self->prereq_phase,
    },
    %{ $self->_prereq },
  );
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
