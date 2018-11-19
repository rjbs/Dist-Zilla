package Dist::Zilla::Role::Plugin;
# ABSTRACT: something that gets plugged in to Dist::Zilla

use Moose::Role;
with 'Dist::Zilla::Role::ConfigDumper';

use Dist::Zilla::Dialect;

use namespace::autoclean;

use Params::Util qw(_HASHLIKE);
use Moose::Util::TypeConstraints 'class_type';

=head1 DESCRIPTION

The Plugin role should be applied to all plugin classes.  It provides a few key
methods and attributes that all plugins will need.

=attr plugin_name

The plugin name is generally determined when configuration is read.

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
  isa => class_type('Dist::Zilla'),
  required => 1,
  weak_ref => 1,
);

=method log

The plugin's C<log> method delegates to the Dist::Zilla object's
L<Dist::Zilla/log> method after including a bit of argument-munging.

=cut

has logger => (
  is   => 'ro',
  lazy => 1,
  handles => [ qw(log log_debug log_fatal) ],
  default => sub {
    $_[0]->zilla->chrome->logger->proxy({
      proxy_prefix => '[' . $_[0]->plugin_name . '] ',
    });
  },
);

# We define these effectively-pointless subs here to allow other roles to
# modify them with around. -- rjbs, 2010-03-21
sub mvp_multivalue_args {};
sub mvp_aliases         { return {} };

sub plugin_from_config {
  my ($class, $name, $arg, $section) = @_;

  my $self = $class->new({
    %$arg,
    plugin_name => $name,
    zilla       => $section->sequence->assembler->zilla,
  });
}

sub register_component {
  my ($class, $name, $arg, $section) = @_;

  my $self = $class->plugin_from_config($name, $arg, $section);

  my $version = $self->VERSION || 0;

  $self->log_debug([ 'online, %s v%s', $self->meta->name, $version ]);

  $self->zilla->_add_plugin($self);

  return;
}

1;
