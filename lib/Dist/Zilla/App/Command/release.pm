use strict;
use warnings;
package Dist::Zilla::App::Command::release;
# ABSTRACT: release your dist to the CPAN
use Dist::Zilla::App -command;

sub abstract { 'test your dist' }

sub run {
  my ($self, $opt, $arg) = @_;

  Carp::croak("you can't release without any Releaser plugins")
    unless my @releasers = $self->plugins_with(-Releaser)->flatten;

  my $tgz = $self->zilla->build_archive;

  $_->release($tgz) for @releasers;
}

1;
