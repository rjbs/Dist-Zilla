use strict;
use warnings;
package Dist::Zilla::App::Command::nop;
# ABSTRACT: initialize dzil, then exit
use Dist::Zilla::App -command;

=head1 SYNOPSIS

  dzil nop

=head1 DESCRIPTION

This command does nothing.  It initializes Dist::Zill, then exits.  This is
useful to see the logging output of plugin initialization.

Seriously, this command is almost entirely for diagnostic purposes.  Don't
overthink it, okay?

=head1 EXAMPLE

  $ dzil nop -v

=cut

sub abstract { 'do nothing: initialize dzil, then exit' }

sub execute {
  my ($self, $opt, $arg) = @_;

  $self->zilla;
}

1;
