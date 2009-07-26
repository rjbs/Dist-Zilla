package Dist::Zilla::ConfigRole::MVP;
use Moose::Role;
# ABSTRACT: something that converts Config::MVP sequences to config structs

use Dist::Zilla::Util::MVPAssembler;

=head1 DESCRIPTION

The MVP config role provides some helpers for writing a configuration loader
that will use the L<Config::MVP|Config::MVP> system to load and validate its
configuration.  (This will probably be most configuration loaders.)

=attr assembler

The L<assembler> attribute must be a Config::MVP::Assembler, has a sensible
default that will handle the standard needs of a config loader.  Namely, it
will be pre-loaded with a starting section for root configuration.  That
starting section will alias C<author> to C<authors> and will set that up as a
multivalue argument.

=cut

has assembler => (
  is   => 'ro',
  isa  => 'Config::MVP::Assembler',
  lazy => 1,
  default => sub {
    my $assembler = Dist::Zilla::Util::MVPAssembler->new;

    my $root = $assembler->section_class->new({
      name => '_',
      aliases => { author => 'authors' },
      multivalue_args => [ qw(authors) ],
    });

    $assembler->sequence->add_section($root);

    return $assembler;
  }
);

sub config_struct {
  my ($self) = @_;

  my @sections = $self->assembler->sequence->sections;

  my $root_config = (shift @sections)->payload;

  my @plugins;
  for my $section (@sections) {
    my $config = { %{ $section->payload } };
    push @plugins, [ $section->name => $section->package => $config ];
  }

  return ($root_config, \@plugins);
}

no Moose::Role;
1;
