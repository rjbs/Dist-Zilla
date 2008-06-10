use strict;
use warnings;
package Dist::Zilla::App::Command::build;
# ABSTRACT: build your dist
use Dist::Zilla::App -command;

sub abstract { 'build your dist' }

sub opt_spec {
  [ 'tgz!', 'build a tarball (default behavior)', { default => 1 } ]
}

sub run {
  my ($self, $opt, $arg) = @_;

  my $method = $opt->{tgz} ? 'build_archive' : 'build_in';
  $self->zilla->$method;
}

1;
