use strict;
use warnings;
package Dist::Zilla::App::Command::clean;
# ABSTRACT: clean up after build, test, or install
use Dist::Zilla::App -command;

sub abstract { 'clean up after build, test, or install' }

sub run {
  my ($self, $opt, $arg) = @_;

  require File::Path;
  for my $x (grep { -e } '.build', glob($self->zilla->name . '-*')) {
    $self->log("clean: removing $x");
    File::Path::rmtree($x);
  };
}

1;
