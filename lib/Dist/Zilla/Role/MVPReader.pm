package Dist::Zilla::Role::MVPReader;
use Moose::Role;
# ABSTRACT: stored configuration loader role

use Config::MVP 2; # finalization and what not

use Dist::Zilla::MVP::Assembler::GlobalConfig;
use Dist::Zilla::MVP::Assembler::Zilla;

use MooseX::Types::Perl qw(PackageName);

=head1 DESCRIPTION

The config role provides some helpers for writing a configuration loader using
the L<Config::MVP|Config::MVP> system to load and validate its configuration.

=attr assembler

The L<assembler> attribute must be a Config::MVP::Assembler, has a sensible
default that will handle the standard needs of a config loader.  Namely, it
will be pre-loaded with a starting section for root configuration.  That
starting section will alias C<author> to C<authors> and will set that up as a
multivalue argument.

=cut

has assembler_class => (
  is  => 'ro',
  isa => PackageName,
);

sub build_assembler {
  my ($self) = @_;

  confess "neither assembler nor assembler_class were provided"
    unless my $assembler_class = $self->assembler_class;

  return $assembler_class->new
}

no Moose::Role;
1;
