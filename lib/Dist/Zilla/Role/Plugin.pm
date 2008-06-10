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
  init_arg => '=name',
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
  handles  => [ qw(log) ],
);

=method log

The plugin's C<log> method delegates to the Dist::Zilla object's
L<Dist::Zilla/log> method.

=cut

no Moose::Role;
1;
