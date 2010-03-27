package Dist::Zilla::Role::PluginBundle;
# ABSTRACT: something that bundles a bunch of plugins
use Moose::Role;

=head1 DESCRIPTION

When loading configuration, if the config reader encounters a PluginBundle, it
will replace its place in the plugin list with the result of calling its
C<bundle_config> method, which will be passed a Config::MVP::Section to
configure the bundle.

=cut

requires 'bundle_config';

no Moose::Role;
1;
