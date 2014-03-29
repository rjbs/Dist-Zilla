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

You can specify requirements for different phases and relationships with:

  [Prereqs]
  -phase = test
  -relationship = recommends

  Fitz::Fotz    = 1.23
  Text::SoundEx = 3

Remember that if you load two Prereqs plugins, each will needs its own name,
added like this:

  [Prereqs / PluginName]
  -phase = test
  -relationship = recommends

  Fitz::Fotz    = 1.23
  Text::SoundEx = 3

If the name is the CamelCase concatenation of a phase and relationship
(or just a relationship), it will set those parameters implicitly.  If
you use a custom name, but it does not specify the relationship, and
you didn't specify either C<-phase> or C<-relationship>, it throws the
error C<No -phase or -relationship specified>.  This is to prevent a
typo that makes the name meaningless from slipping by unnoticed.

The example below is equivalent to the example above, except for the name of
the resulting plugin:

  [Prereqs / TestRecommends]
  Fitz::Fotz    = 1.23
  Text::SoundEx = 3

=head1 DESCRIPTION

This module adds "fixed" prerequisites to your distribution.  These are prereqs
with a known, fixed minimum version that doesn't change based on platform or
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

has prereq_phase => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  init_arg => 'phase',
  default  => 'runtime',
);

has prereq_type => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  init_arg => 'type',
  default  => 'requires',
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

sub mvp_aliases { return { -relationship => '-type' } }

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

  # Handle magic plugin names:
  unless (($other{phase} and $other{type})
          or $name =~ m! (?: \A | / ) Prereqs? \z !x) {

    my ($phase, $type) = $name =~ /\A
      (Build|Test|Runtime|Configure|Develop)?
      (Requires|Recommends|Suggests|Conflicts)
    \z/x;

    if ($type) {
      $other{phase} ||= lc $phase if defined $phase;
      $other{type}  ||= lc $type;
    } else {
      $zilla->chrome->logger->log_fatal({ prefix => "[$name] " },
                                      "No -phase or -relationship specified")
        unless $other{phase} or $other{type};
    }
  }

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

=head1 SEE ALSO

=over 4

=item *

Core Dist::Zilla plugins:
L<@Basic|Dist::Zilla::PluginBundle::Basic>,
L<AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs>.

=item *

The CPAN Meta specification: L<CPAN::Meta/PREREQUISITES>.

=back

=cut
