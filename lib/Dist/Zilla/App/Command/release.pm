use strict;
use warnings;
package Dist::Zilla::App::Command::release;
# ABSTRACT: release your dist to the CPAN

use Dist::Zilla::App -command;

=head1 SYNOPSIS

  dzil release

  dzil release --trial

  dzil release --no-tgz

This command is a very, very thin wrapper around the
C<L<release|Dist::Zilla/release>> method on the Dist::Zilla object.  It will
build, archive, and release your distribution using your Releaser plugins.  The
only option, C<--trial>, will cause it to build a trial build.

=cut

sub abstract { 'release your dist' }

sub opt_spec {
  [ 'trial' => 'build a trial release that PAUSE will not index' ],
  [ 'tgz!' => 'build a tarball as part of the release', { default => 1 } ],
}

sub execute {
  my ($self, $opt, $arg) = @_;

  my $zilla = $self->zilla;

  $zilla->is_trial(1) if $opt->trial;
  $zilla->should_build_archive(0) unless $opt->tgz;

  $self->zilla->release;
}

1;
