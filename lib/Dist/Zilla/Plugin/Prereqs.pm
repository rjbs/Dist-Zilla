package Dist::Zilla::Plugin::Prereqs;
# ABSTRACT: list simple prerequisites
use Moose;
with 'Dist::Zilla::Role::PrereqSource';

use namespace::autoclean;

=head1 SYNOPSIS

In your F<dist.ini>:

  [Prereqs]
  Foo::Bar = 1.002
  MRO::Compat = 10
  Sub::Exporter = 0

Which is equivalent to specifying prerequisites for the C<Runtime>
phase:

  [Prereqs / RuntimeRequires]
  Foo::Bar = 1.002
  MRO::Compat = 10
  Sub::Exporter = 0

See L</Phases> for the full list of supported phases.

=head1 DESCRIPTION

This module adds "fixed" prerequisites to your distribution.  These are prereqs
with a known, fixed minimum version that doens't change based on platform or
other conditions.

You can specify prerequisites for different phases and kinds of relationships.
In C<RuntimeRequires>, the phase is Runtime and the relationship is Requires.
These are described in more detail in the L<CPAN::Meta
specification|CPAN::Meta::Spec/PREREQUISITES>.

The phases are:

=for :list
* configure
* build
* test
* runtime
* develop

The relationship types are:

=for :list
* requires
* recommends
* suggests
* conflicts

If the phase is omitted, it will default to I<runtime>; thus, specifying
"Prereqs / Recommends" in your dist.ini is equivalent to I<RuntimeRecommends>.

Not all of these phases are useful for all tools, especially tools that only
understand version 1.x CPAN::Meta files.

=cut

sub __from_name {
  my ($self) = @_;
  my $name = $self->plugin_name;

  # such as C<configure>, C<build>, C<test> and C<runtime>.  Values are
  # relationship such as C<requires>, C<prefers>, or C<recommends>.  The
  # phase component is optional and will default to Runtime.

  my ($phase, $type) = $name =~ /\A
    (Build|Test|Runtime|Configure|Develop)?
    (Requires|Recommends|Suggests|Conflicts)
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

__PACKAGE__->meta->make_immutable;
1;
