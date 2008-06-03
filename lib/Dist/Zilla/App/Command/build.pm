use strict;
use warnings;
package Dist::Zilla::App::Command::build;
use Dist::Zilla::App -command;

sub abstract { 'build your dist' }

sub opt_spec {
  [ 'tgz!', 'build a tarball (default behavior)', { default => 1 } ],
}

sub run {
  my ($self, $opt, $arg) = @_;

  $self->zilla->build_dist({
    build_tarball => $opt->{tgz},
  });
}

1;
