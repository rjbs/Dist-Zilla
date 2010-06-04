use strict;
use warnings;
package Dist::Zilla::App::Command::listdeps;
use Dist::Zilla::App -command;
# ABSTRACT: print your distribution's prerequisites

=head1 SYNOPSIS

  $ dzil listdeps | cpan

=head1 DESCRIPTION

This is a command plugin for L<Dist::Zilla>. It provides the C<listdeps>
command, which prints your distribution's prerequisites. You could pipe that
list to a CPAN client like L<cpan> to install all of the dependecies in one
quick go.

=head1 ACKNOWLEDGEMENTS

This code is more or less a direct copy of Marcel Gruenauer (hanekomu)
Dist::Zilla::App::Command::prereqs, updated to work with the Dist::Zilla v2
API.

=cut

use Moose::Autobox;
use Version::Requirements;

sub abstract { "print your distribution's prerequisites" }

sub execute {
  my ($self, $opt, $arg) = @_;

  # ...more proof that we need a ->mute setting for Log::Dispatchouli.
  # -- rjbs, 2010-04-29
  $self->app->chrome->_set_logger(
    Log::Dispatchouli->new({ ident => 'Dist::Zilla' }),
  );

  $_->before_build for $self->zilla->plugins_with(-BeforeBuild)->flatten;
  $_->gather_files for $self->zilla->plugins_with(-FileGatherer)->flatten;
  $_->prune_files  for $self->zilla->plugins_with(-FilePruner)->flatten;
  $_->munge_files  for $self->zilla->plugins_with(-FileMunger)->flatten;
  $_->register_prereqs for $self->zilla->plugins_with(-PrereqSource)->flatten;

  my $req = Version::Requirements->new;
  my $prereqs = $self->zilla->prereqs;

  for my $phase (qw(build test configure runtime)) {
    $req->add_requirements( $prereqs->requirements_for($phase, 'requires') );
  }

  print "$_\n" for sort { lc $a cmp lc $b }
                   grep { $_ ne 'perl' }
                   $req->required_modules;
}

1;
