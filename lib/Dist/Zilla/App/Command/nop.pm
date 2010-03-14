use strict;
use warnings;
package Dist::Zilla::App::Command::nop;
# ABSTRACT: initialize dzil, then exit
use Dist::Zilla::App -command;

=head1 SYNOPSIS

This command does nothing.  It initializes Dist::Zill, then exits.  This is
useful to see the logging output of plugin initialization.

    dzil nop -v

=cut

sub abstract { 'do nothing: initialize dzil, then exit' }

sub opt_spec {
}

sub execute {
  my ($self, $opt, $arg) = @_;

  $self->zilla;
}

1;
