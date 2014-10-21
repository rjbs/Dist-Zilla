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

  return
    if -e 'Build' and (stat 'Build.PL')[9] <= (stat 'Build')[9];

  $self->log_debug("running $^X Build.PL");
  system $^X, 'Build.PL' and die "error with Build.PL\n";

  $self->log_debug("running $^X Build");
  system $^X, 'Build'    and die "error running $^X Build\n";

  return;
}

sub test {
  my ($self, $target, $arg) = @_;

  $self->build;

  my $job_count = $arg && exists $arg->{jobs}
                ? $arg->{jobs}
                : $self->default_jobs;
  my $jobs = "j$job_count";
  my $ho = "HARNESS_OPTIONS";
  local $ENV{$ho} = $ENV{$ho} ? "$ENV{$ho}:$jobs" : $jobs;

  my @testing = $self->zilla->logger->get_debug ? '--verbose' : ();

  $self->log_debug('running ' . join(' ', $^X, 'Build', 'test', @testing));
  system $^X, 'Build', 'test', @testing and die "error running $^X Build test\n";

  return;
}

1;
