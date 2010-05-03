use strict;
use warnings;
package Dist::Zilla::App::Command::new;
# ABSTRACT: start a new dist
use Dist::Zilla::App -command;

=head1 SYNOPSIS

Creates a new Dist-Zilla based distribution under the current directory.

  $ dzil new Main::Module::Name

=cut

use Dist::Zilla::Types qw(DistName);
use Moose::Autobox;
use Path::Class;

sub abstract { 'start a new dist' }

sub validate_args {
  my ($self, $opt, $args) = @_;

  $self->usage_error('dzil new takes exactly one argument') if @$args != 1;

  my $name = $args->[0];

  $self->usage_error("$name is not a valid distribution name")
    unless is_DistName($args->[0]);
}

sub opt_spec {
  [ 'profile|p=s', 'name of the profile to use', { default => 'default' } ],
}

sub execute {
  my ($self, $opt, $arg) = @_;

  my $dist = $arg->[0];

  require Dist::Zilla;
  my $minter = Dist::Zilla->_new_from_profile(
    $opt->profile => {
      chrome => $self->app->chrome,
      name   => $dist,
    },
  );

  $minter->mint_dist({ name => $dist });
}

1;
