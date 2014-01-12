use strict;
use warnings;
package Dist::Zilla::App::Command::release;
# ABSTRACT: release your dist to the CPAN

use Dist::Zilla::App -command;

=head1 SYNOPSIS

  dzil release

  dzil release --trial

This command is a very, very thin wrapper around the
C<L<release|Dist::Zilla/release>> method on the Dist::Zilla object.  It will
build, archive, and release your distribution using your Releaser plugins.  The
only option, C<--trial>, will cause it to build a trial build.

=cut

sub abstract { 'release your dist' }

sub opt_spec {
  [ 'trial' => 'build a trial release that PAUSE will not index' ],
}

sub execute {
  my ($self, $opt, $arg) = @_;

  my $zilla = $self->zilla;

  $zilla->is_trial(1) if $opt->trial;

  $self->zilla->release;
}

1;
