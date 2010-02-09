use strict;
use warnings;
package Dist::Zilla::App::Command;
# ABSTRACT: base class for dzil commands
use App::Cmd::Setup -command;
use Moose::Autobox;

=method zilla

This returns the Dist::Zilla object in use by the command.  If none has yet
been constructed, one will be by calling C<< Dist::Zilla->from_config >>.

=cut

sub zilla {
  my ($self) = @_;

  require Dist::Zilla;
  return $self->{__PACKAGE__}{zilla} ||= do {
    my $zilla = Dist::Zilla->from_config;
    $zilla->dzil_app($self->app);
    $zilla;
  }
}

=method config

This method returns the configuration for the current command.

=cut

sub config {
  my ($self) = @_;
  return $self->{__PACKAGE__}{config} ||= $self->app->config_for(ref $self);
}

=method log

This method calls the C<log> method of the command's L<Dist::Zilla|Dist::Zilla>
object.

=cut

sub log {
  $_[0]->zilla->log($_[1]);
}

1;
