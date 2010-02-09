package Dist::Zilla::Role::Plugin;
# ABSTRACT: something that gets plugged in to Dist::Zilla
use Moose::Role;

=head1 DESCRIPTION

The Plugin role should be applied to all plugin classes.  It provides a few key
methods and attributes that all plugins will need.

=attr plugin_name

The plugin name is generally determined when configuration is read.  It is
initialized by the C<=name> argument to the plugin's constructor.

=cut

has plugin_name => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

=attr zilla

This attribute contains the Dist::Zilla object into which the plugin was
plugged.

=cut

has zilla => (
  is  => 'ro',
  isa => 'Dist::Zilla',
  required => 1,
  weak_ref => 1,
);

=method log

The plugin's C<log> method delegates to the Dist::Zilla object's
L<Dist::Zilla/log> method after including a bit of argument-munging.

=cut

sub log {
  my ($self, $arg) = @_;

  if (ref($arg)) {
    my ($fmt, @arg) = @$arg;
    return $self->zilla->log([ "[%s] $fmt", $self->plugin_name, @arg ]);
  } else {
    return $self->zilla->log(sprintf '[%s] %s', $self->plugin_name, $arg);
  }
}

no Moose::Role;
1;
