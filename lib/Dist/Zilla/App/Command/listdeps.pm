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
quick go. This will include author dependencies (those listed under
C<develop_requires>) if the C<--author> flag is passed. You can also pass the
C<--missing> flag to list only dependencies which are unsatisfied.

=head1 ACKNOWLEDGEMENTS

This code is more or less a direct copy of Marcel Gruenauer (hanekomu)
Dist::Zilla::App::Command::prereqs, updated to work with the Dist::Zilla v2
API.

=cut

use Try::Tiny;

sub abstract { "print your distribution's prerequisites" }

sub opt_spec {
  [ 'author', 'include author dependencies' ],
  [ 'missing', 'list only the missing dependencies' ],
  [ 'versions', 'include required version numbers in listing' ]
}

sub extract_dependencies {
  my ($self, $zilla, $phases, $missing) = @_;

  $_->before_build for @{ $zilla->plugins_with(-BeforeBuild) };
  $_->gather_files for @{ $zilla->plugins_with(-FileGatherer) };
  $_->prune_files  for @{ $zilla->plugins_with(-FilePruner) };
  $_->munge_files  for @{ $zilla->plugins_with(-FileMunger) };
  $_->register_prereqs for @{ $zilla->plugins_with(-PrereqSource) };

  require CPAN::Meta::Requirements;
  my $req = CPAN::Meta::Requirements->new;
  my $prereqs = $zilla->prereqs;

  for my $phase (@$phases) {
    $req->add_requirements( $prereqs->requirements_for($phase, 'requires') );
    $req->add_requirements( $prereqs->requirements_for($phase, 'recommends') );
  }

  require Class::Load;

  my @required = grep { $_ ne 'perl' } $req->required_modules;
  if ($missing) {
    my $is_required = sub {
      my $mod = shift;
      # it is required if it's not already installed
      return 1 unless Class::Load::try_load_class($mod);
      # it is required if the version can't be parsed
      # right now $_->VERSION by itself will die if the version can't
      # be parsed, but this may change in the future to only die in that
      # way if an arg is passed
      return 1 if ! try { $mod->VERSION(0); 1 };
      # it is required if the version doesn't meet the requirement
      return !$req->accepts_module($mod => $mod->VERSION);
    };
    @required = grep { $is_required->($_) } @required;
  }

  my $versions = $req->as_string_hash;
  return map { $_ => $versions->{$_} } @required;
}

sub execute {
  my ($self, $opt, $arg) = @_;

  $self->app->chrome->logger->mute;

  my @phases = qw(build test configure runtime);
  push @phases, 'develop' if $opt->author;

  my %modules = $self->extract_dependencies($self->zilla, \@phases, $opt->missing);

  if($opt->versions) {
    for(sort { lc $a cmp $b } keys %modules) {
      print "$_ = ".$modules{$_}."\n";
    }
  } else {
      print "$_\n" for sort { lc $a cmp lc $b } keys(%modules);
  }
}

1;
