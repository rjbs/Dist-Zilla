package Dist::Zilla::Role::PluginBundle;
# ABSTRACT: something that bundles a bunch of plugins

use Moose::Role;

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

=head1 DESCRIPTION

When loading configuration, if the config reader encounters a PluginBundle, it
will replace its place in the plugin list with the result of calling its
C<bundle_config> method, which will be passed a Config::MVP::Section to
configure the bundle.

=cut

sub register_component {
  my ($class, $name, $arg, $self) = @_;
  # ... we should register a placeholder so MetaConfig can tell us about the
  # pluginbundle that was loaded
}

requires 'bundle_config';

1;
