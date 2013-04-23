package Dist::Zilla::Role::BuildPL;
use Moose::Role;

with qw(
  Dist::Zilla::Role::InstallTool
  Dist::Zilla::Role::BuildRunner
  Dist::Zilla::Role::TestRunner
);

use namespace::autoclean;

sub build {
  my $self = shift;

  my $perl = $ENV{DZIL_PERL} ? $ENV{DZIL_PERL} : $^X;
  system $perl, 'Build.PL' and die "error with Build.PL\n";
  system $perl, 'Build'    and die "error running $^X Build\n";

  return;
}

sub test {
  my ($self, $target) = @_;

  $self->build;
  my @testing = $self->zilla->logger->get_debug ? '--verbose' : ();
  my $perl = $ENV{DZIL_PERL} ? $ENV{DZIL_PERL} : $^X;
  system $perl, 'Build', 'test', @testing
    and die "error running $^X Build test\n";

  return;
}

1;

# ABSTRACT: Common ground for Build.PL based builders

=head1 DESCRIPTION

This role is a helper for Build.PL based installers. It implements the L<Dist::Zilla::Plugin::BuildRunner> and L<Dist::Zilla::Plugin::TestRunner> roles, and requires you to implement the L<Dist::Zilla::Plugin::PrereqSource> and L<Dist::Zilla::Plugin::InstallTool> roles yourself.

=cut

