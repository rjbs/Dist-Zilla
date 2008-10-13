use strict;
use warnings;
package Dist::Zilla::App::Command::release;
# ABSTRACT: release your dist to the CPAN
use Dist::Zilla::App -command;

sub abstract { 'test your dist' }

sub run {
  my ($self, $opt, $arg) = @_;
  
  my $tgz = $self->zilla->build_archive;

  $_->release($tgz) for $self->plugins_with(-Release)->flatten;
}

1;
