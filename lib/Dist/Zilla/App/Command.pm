use strict;
use warnings;
package Dist::Zilla::App::Command;
# ABSTRACT: base class for dzil commands
use App::Cmd::Setup -command;

sub zilla {
  my ($self) = @_;

  require Dist::Zilla;
  return $self->{__PACKAGE__}{zilla} ||= Dist::Zilla->from_config;
}

sub log { shift->zilla->log(@_) } ## no critic

1;
