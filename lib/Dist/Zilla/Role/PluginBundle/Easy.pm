package Dist::Zilla::Role::PluginBundle::Easy;
# ABSTRACT: something that bundles a bunch of plugins easily
# This plugin was originally contributed by Christopher J. Madsen
use Moose::Role;
with 'Dist::Zilla::Role::PluginBundle';

=head1 SYNOPSIS

  package Dist::Zilla::PluginBundle::Example;
  use Moose;
  with 'Dist::Zilla::Role::PluginBundle::Easy';

  sub configure {
    my $self = shift;

    $self->add_plugins('VersionFromModule');
    $self->add_bundle('Basic');
  }

=head1 DESCRIPTION

This role builds upon the PluginBundle role, adding methods to take most of the
grunt work out of creating a bundle.  It supplies the C<bundle_config> method
for you.  In exchange, you must supply a C<configure> method, which will store
the bundle's configuration in the C<plugins> attribute by calling
C<add_plugins> and/or C<add_bundle>.

=cut

use Moose::Autobox;
use MooseX::Types::Moose qw(Str ArrayRef HashRef);

use String::RewritePrefix 0.005
  rewrite => {
    -as => '_plugin_class',
    prefixes => { '' => 'Dist::Zilla::Plugin::', '=' => '' },
  },
  rewrite => {
    -as => '_bundle_class',
    prefixes => {
      ''  => 'Dist::Zilla::PluginBundle::',
      '@' => 'Dist::Zilla::PluginBundle::',
      '=' => ''
    },
  };

use namespace::autoclean;

requires 'configure';

=attr name

This is the bundle name, taken from the Section passed to
C<bundle_config>.

=cut

has name => (
  is       => 'ro',
  isa      => Str,
  required => 1,
);

=attr payload

This hashref contains the bundle's parameters (if any), taken from the
Section passed to C<bundle_config>.

=cut

has payload => (
  is       => 'ro',
  isa      => HashRef,
  required => 1,
);

=attr plugins

This arrayref contains the configuration that will be returned by
C<bundle_config>.  You normally modify this by using the
C<add_plugins> and C<add_bundle> methods.

=cut

has plugins => (
  is       => 'ro',
  isa      => ArrayRef,
  default  => sub { [] },
);

sub bundle_config {
  my ($class, $section) = @_;

  my $self = $class->new($section);

  $self->configure;

  return $self->plugins->flatten;
}

=method add_plugins

  $self->add_plugins('Plugin1', [ Plugin2 => \%plugin2config ])

Use this method to add plugins to your bundle.

It is passed a list of plugin specifiers, which can be one of a few things:

=for :list
* a plugin moniker (like you might provide in your config file)
* an arrayref of: C<< [ $moniker, $plugin_name, \%plugin_config >>

In the case of an arrayref, both C<$plugin_name> and C<\%plugin_config> are
optional.

The plugins are added to the config in the order given.

=cut

sub add_plugins {
  my ($self, @plugin_specs) = @_;

  my $prefix  = $self->name . '/';
  my $plugins = $self->plugins;

  foreach my $this_spec (@plugin_specs) {
    my $moniker;
    my $name;
    my $payload;

    if (! ref $this_spec) {
      ($moniker, $name, $payload) = ($this_spec, $this_spec, {});
    } elsif (@$this_spec == 1) {
      ($moniker, $name, $payload) = ($this_spec->[0], $this_spec->[0], {});
    } elsif (@$this_spec == 2) {
      $moniker = $this_spec->[0];
      $name    = ref $this_spec->[1] ? $moniker : $this_spec->[1];
      $payload = ref $this_spec->[1] ? $this_spec->[1] : {};
    } else {
      ($moniker, $name, $payload) = @$this_spec;
    }

    push @$plugins, [ $prefix . $name => _plugin_class($moniker) => $payload ];
  }
}

=method add_bundle

  $self->add_bundle(BundleName => \%bundle_config)

Use this method to add all the plugins from another bundle to your bundle.  If
you omit C<%bundle_config>, an empty hashref will be supplied.

=cut

sub add_bundle {
  my ($self, $bundle, $payload) = @_;

  my $package = _bundle_class($bundle);
  $payload  ||= {};

  Class::MOP::load_class($package);

  $bundle = "\@$bundle" unless $bundle =~ /^@/;

  $self->plugins->push(
    $package->bundle_config({
      name    => $self->name . '/' . $bundle,
      package => $package,
      payload => $payload,
    })
  );
}

=method config_slice

  $hash_ref = $self->config_slice(arg1, { arg2 => 'plugin_arg2' })

Use this method to extract parameters from your bundle's C<payload> so
that you can pass them to a plugin or subsidiary bundle.  It supports
easy renaming of parameters, since a plugin may expect a parameter
name that's too generic to be suitable for a bundle.

Each arg is either a key in C<payload>, or a hashref that maps keys in
C<payload> to keys in the hash being constructed.  If any specified
key does not exist in C<payload>, then it is omitted from the result.

=cut

sub config_slice {
  my $self = shift;

  my $payload = $self->payload;

  my %arg;

  foreach my $arg (@_) {
    if (ref $arg) {
      while (my ($in, $out) = each %$arg) {
        $arg{$out} = $payload->{$in} if exists $payload->{$in};
      }
    } else {
      $arg{$arg} = $payload->{$arg} if exists $payload->{$arg};
    }
  }

  return \%arg;
}

1;
