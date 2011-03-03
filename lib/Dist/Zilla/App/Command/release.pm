use strict;
use warnings;
package Dist::Zilla::App::Command::release;
# ABSTRACT: release your dist to the CPAN
use Dist::Zilla::App -command;

=head1 SYNOPSIS

  dzil release [ --trial ]

=head1 DESCRIPTION

This command is a thin wrapper around the L<release|Dist::Zilla::Dist::Builder/release>
method in Dist::Zilla.  It will build, archive, and release your distribution using
your Releaser plugins.

=head1 EXAMPLE

  $ dzil release
  $ dzil release --trial

=head1 OPTIONS

=head2 --trial

Releases your distribution as a TRIAL release that PAUSE will not index.

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
