package Dist::Zilla::Plugin::MakeMaker::Runner;
# ABSTRACT: Test and build dists with a Makefile.PL

use Moose;
with(
  'Dist::Zilla::Role::BuildRunner',
  'Dist::Zilla::Role::TestRunner',
);

use Dist::Zilla::Dialect;

use namespace::autoclean;

use Config;

has 'make_path' => (
  isa => 'Str',
  is  => 'ro',
  default => $Config{make} || 'make',
);

sub build ($self) {
  my $make = $self->make_path;

  my $makefile = $^O eq 'VMS' ? 'Descrip.MMS' : 'Makefile';

  return
    if -e $makefile and (stat 'Makefile.PL')[9] <= (stat $makefile)[9];

  $self->log_debug("running $^X Makefile.PL");
  system($^X => qw(Makefile.PL INSTALLMAN1DIR=none INSTALLMAN3DIR=none)) and die "error with Makefile.PL\n";

  $self->log_debug("running $make");
  system($make) and die "error running $make\n";

  return;
}

sub test ($self, $target, $arg = {}) {
  my $make = $self->make_path;
  $self->build;

  my $job_count = $arg && exists $arg->{jobs}
                ? $arg->{jobs}
                : $self->default_jobs;

  my $jobs = "j$job_count";
  my $ho = "HARNESS_OPTIONS";
  local $ENV{$ho} = $ENV{$ho} ? "$ENV{$ho}:$jobs" : $jobs;

  $self->log_debug(join(' ', "running $make test", ( $self->zilla->logger->get_debug ? 'TEST_VERBOSE=1' : () )));
  system($make, 'test',
    ( $self->zilla->logger->get_debug || $arg->{test_verbose} ? 'TEST_VERBOSE=1' : () ),
  ) and die "error running $make test\n";

  return;
}

__PACKAGE__->meta->make_immutable;
1;
