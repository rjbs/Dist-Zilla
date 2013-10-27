use strict;
use warnings;

package Dist::Zilla::App::Command::version;
use Dist::Zilla::App -command;

# ABSTRACT: display dzil's version

=head1 SYNOPSIS

Print dzil version

  $ dzil --version or $dzil version

=cut

sub command_names { qw/version --version/ }

sub version_for_display {
  $_[0]->version_package->VERSION
}

sub version_package {
  ref($_[0]->app)
}

sub execute {
  my ($self, $opts, $args) = @_;
  my $ver = $self->version_for_display;

  my $version = ( $ver ? $ver : "dev" );

  printf "%s (%s) version %s (%s)\n",
    $self->app->arg0, $self->version_package,
    $version, $self->app->full_arg0;
}

1;
