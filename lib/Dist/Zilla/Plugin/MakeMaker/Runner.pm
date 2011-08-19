package Dist::Zilla::Plugin::MakeMaker::Runner;
# ABSTRACT: Test and build dists with a Makefile.PL

use Moose;
with(
  'Dist::Zilla::Role::BuildRunner',
  'Dist::Zilla::Role::TestRunner',
);

use namespace::autoclean;

use Config;

has 'make_path' => (
  isa => 'Str',
  is  => 'ro',
  default => $Config{make} || 'make',
);

sub build {
  my $self = shift;

  my $make = $self->make_path;
  system($^X => 'Makefile.PL') and die "error with Makefile.PL\n";
  system($make)                and die "error running $make\n";

  return;
}

sub test {
  my ( $self, $target ) = @_;

  my $make = $self->make_path;
  $self->build;
  system($make, 'test',
    ( $self->zilla->logger->get_debug ? 'TEST_VERBOSE=1' : () ),
  ) and die "error running $make test\n";

  return;
}

__PACKAGE__->meta->make_immutable;
1;
