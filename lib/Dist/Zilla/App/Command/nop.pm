package Dist::Zilla::App::Command::nop;
# ABSTRACT: initialize dzil, then exit

use Dist::Zilla::Pragmas;

use Dist::Zilla::App -command;

=head1 SYNOPSIS

This command does nothing.  It initializes Dist::Zilla, then exits.  This is
useful to see the logging output of plugin initialization.

  dzil nop -v

Seriously, this command is almost entirely for diagnostic purposes.  Don't
overthink it, okay?

=cut

sub abstract { 'do nothing: initialize dzil, then exit' }

sub description {
  "This command does nothing but initialize Dist::Zilla and exit.\n" .
  "It is sometimes useful for diagnostic purposes."
}

sub execute ($self, $opt, $arg) {
  $self->zilla;
}

1;
