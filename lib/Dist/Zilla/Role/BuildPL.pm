package Dist::Zilla::Role::BuildPL;
# ABSTRACT: Common ground for Build.PL based builders

use Moose::Role;

with qw(
  Dist::Zilla::Role::InstallTool
  Dist::Zilla::Role::BuildRunner
  Dist::Zilla::Role::TestRunner
);

use namespace::autoclean;

=head1 DESCRIPTION

This role is a helper for Build.PL based installers. It implements the
L<Dist::Zilla::Plugin::BuildRunner> and L<Dist::Zilla::Plugin::TestRunner>
roles, and requires you to implement the L<Dist::Zilla::Plugin::PrereqSource>
and L<Dist::Zilla::Plugin::InstallTool> roles yourself.

=cut

sub build {
  my $self = shift;

  system $^X, 'Build.PL' and die "error with Build.PL\n";
  system $^X, 'Build'    and die "error running $^X Build\n";

  return;
}

sub test {
  my ($self, $target, $arg) = @_;

  $self->build;

  my $jobs = $arg ? "j" . $arg->{jobs} : '';
  my $ho = "HARNESS_OPTIONS";
  local $ENV{$ho} = $ENV{$ho} ? "$ENV{$ho}:$jobs" : $jobs
    if $jobs;

  my @testing = $self->zilla->logger->get_debug ? '--verbose' : ();
  system $^X, 'Build', 'test', @testing and die "error running $^X Build test\n";

  return;
}

1;
