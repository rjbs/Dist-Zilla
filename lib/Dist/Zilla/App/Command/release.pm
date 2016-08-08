use strict;
use warnings;
package Dist::Zilla::App::Command::release;
# ABSTRACT: release your dist to the CPAN

use Dist::Zilla::App -command;

=head1 SYNOPSIS

  dzil release

  dzil release [ --trial ] [ --clean ]

This command is a very, very thin wrapper around the
C<L<release|Dist::Zilla/release>> method on the Dist::Zilla object.  It will
build, archive, and release your distribution using your Releaser plugins.  The
only option, C<--trial>, will cause it to build a trial build. C<--clean> will
run C<dzil clean> after the release.

=cut

sub abstract { 'release your dist' }

sub opt_spec {
  [ 'trial' => 'build a trial release that PAUSE will not index' ],
  [ 'clean' => 'clean up after release' ]
}

sub execute {
  my ($self, $opt, $arg) = @_;

  my $zilla;
  {
    # isolate changes to RELEASE_STATUS to zilla construction
    local $ENV{RELEASE_STATUS} = $ENV{RELEASE_STATUS};
    $ENV{RELEASE_STATUS} = 'testing' if $opt->trial;
    $zilla = $self->zilla;
  }

  $self->zilla->release;

  $self->zilla->clean if $opt->clean;
}

1;
