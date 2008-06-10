use strict;
use warnings;
package Dist::Zilla::App::Command;
# ABSTRACT: base class for dzil commands
use App::Cmd::Setup -command;

=method zilla

This returns the Dist::Zilla object in use by the command.  If none has yet
been constructed, one will be by calling C<< Dist::Zilla->from_config >>.

=cut

sub zilla {
  my ($self) = @_;

  require Dist::Zilla;
  return $self->{__PACKAGE__}{zilla} ||= Dist::Zilla->from_config;
}

=method log

This method calls the C<log> method of the command's L<Dist::Zilla|Dist::Zilla>
object.

=cut

sub log { shift->zilla->log(@_) } ## no critic

1;
