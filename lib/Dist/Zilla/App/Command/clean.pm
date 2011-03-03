use strict;
use warnings;
package Dist::Zilla::App::Command::clean;
# ABSTRACT: clean up after build, test, or install
use Dist::Zilla::App -command;

use File::Find::Rule;

=head1 SYNOPSIS

  dzil clean

=head1 DESCRIPTION

This command is a thin wrapper around the L<clean|Dist::Zilla::Dist::Builder/clean>
method in Dist::Zilla. It removes some files that are created during build, test, and
install.  The documentation for that method gives more information about the files
that will be removed.

=head1 EXAMPLE

  $ dzil clean

=cut

sub abstract { 'clean up after build, test, or install' }

sub execute {
  my ($self, $opt, $arg) = @_;

  $self->zilla->clean;
}

1;
