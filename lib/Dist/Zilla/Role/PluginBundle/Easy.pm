package Dist::Zilla::Role::PluginBundle::Easy;
# ABSTRACT: something that bundles a bunch of plugins easily
# This plugin was originally contributed by Christopher J. Madsen

use Moose::Role;

=head1 SYNOPSIS

  package Dist::Zilla::PluginBundle::Example;
  use Moose;
  with 'Dist::Zilla::Role::PluginBundle::Easy';

  sub configure
  {
    my $self = shift;

    $self->add_plugins('VersionFromModule');
    $self->add_bundle('Basic');
  }

=head1 DESCRIPTION

This role extends the PluginBundle role with methods to take most of
the grunt work out of creating a bundle.  It supplies the
C<bundle_config> method for you.  Instead, you must supply a
C<configure> method, which will store the bundle's configuration in
the C<plugins> attribute by calling C<add_plugins> and/or
C<add_bundle>.

=cut

with 'Dist::Zilla::Role::PluginBundle';

use Moose::Autobox;
use MooseX::Types::Moose qw(Str ArrayRef HashRef);

use String::RewritePrefix
  rewrite => {
    -as => '_plugin_class',
    prefixes => { '' => 'Dist::Zilla::Plugin::', '=' => '' },
  },
  rewrite => {
    -as => '_bundle_class',
    prefixes => { '' => 'Dist::Zilla::PluginBundle::', '=' => '' },
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
#---------------------------------------------------------------------

sub bundle_config
{
  my ($class, $section) = @_;

  my $self = $class->new($section);

  $self->configure;

  return $self->plugins->flatten;
} # end bundle_config
#---------------------------------------------------------------------

=method add_plugins

  $self->add_plugins('Plugin1', [ Plugin2 => \%plugin2config ])

Use this method to add plugins to your bundle.  Each parameter is
either a plugin name or an arrayref of two elements: the plugin name
and a hashref of parameters for it.  The plugins are appended to the
config in the order given.

=cut

sub add_plugins
{
  my ($self, @newPlugins) = @_;

  my $name    = $self->name . '/';
  my $plugins = $self->plugins;

  foreach my $plugin (@newPlugins) {
    my $payload;

    if (ref $plugin) {
      ($plugin, $payload) = @$plugin;
    }
    $payload ||= {};

    push @$plugins, [ $name . $plugin => _plugin_class($plugin) => $payload ];
  } # end foreach $plugin in @newPlugins
} # end add_plugins
#---------------------------------------------------------------------

=method add_bundle

  $self->add_bundle(BundleName => \%bundleConfig)

Use this method to add all the plugins from another bundle to your
bundle.  If you omit C<%bundleConfig>, an empty hashref will be
supplied.  The plugins are appended to the config.

=cut

sub add_bundle
{
  my ($self, $bundle, $payload) = @_;

  my $package = _bundle_class($bundle);
  $payload  ||= {};

  Class::MOP::load_class($package);

  $self->plugins->push(
    $package->bundle_config({
      name    => $self->name . '/@' . $bundle,
      package => $package,
      payload => $payload,
    })
  );
} # end add_bundle
#---------------------------------------------------------------------

=method get_args

  $hashRef = $self->get_args(arg1, { arg2 => 'plugin_arg2' })
  %hash    = $self->get_args(arg1, { arg2 => 'plugin_arg2' })

Use this method to extract parameters from your bundle's C<payload> so
that you can pass them to a plugin or subsidiary bundle.  It supports
easy renaming of parameters, since a plugin may expect a parameter
name that's too generic to be suitable for a bundle.

Each arg is either a key in C<payload>, or a hashref that maps keys in
C<payload> to keys in the hash being constructed.  If any specified
key does not exist in C<payload>, then it is omitted from the result.

In scalar context, it returns a hashref.  In list context, it returns
the key-value pairs from the hash.

=cut

sub get_args
{
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
  } # end foreach $arg

  wantarray ? %arg : \%arg;
} # end get_args

1;
