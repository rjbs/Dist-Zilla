use strict;
use warnings;
package Dist::Zilla::App::Command::clean;
# ABSTRACT: clean up after build, test, or install

use Dist::Zilla::App -command;

use Dist::Zilla::Dialect;

=head1 SYNOPSIS

  dzil clean [ --dry-run|-n ]

This command removes some files that are created during build, test, and
install.  It's a very thin layer over the C<L<clean|Dist::Zilla/clean>> method
on the Dist::Zilla object.  The documentation for that method gives more
information about the files that will be removed.

=cut

sub opt_spec {
  [ 'dry-run|n'   => 'don\'t actually remove anything, just show what would be done' ],
}

=head1 OPTIONS

=head2 -n, --dry-run

Nothing is removed; instead, everything that would be removed will be listed.

=cut

sub abstract { 'clean up after build, test, or install' }

sub execute {
  my ($self, $opt, $arg) = @_;

  $self->zilla->clean($opt->dry_run);
}

1;
