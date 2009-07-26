package Dist::Zilla::Config;
use Moose::Role;
# ABSTRACT: stored configuration loader role

requires 'read_config';

sub expand_bundles {
  my ($self, $plugins) = @_;

  my @new_plugins;

  for my $plugin (@$plugins) {
    if (eval { $plugin->[1]->does('Dist::Zilla::Role::PluginBundle') }) {
      confess "arguments attempted to override plugin bundle name"
        if defined $plugin->[2]->{plugin_name};

      push @new_plugins, $plugin->[1]->bundle_config({
        plugin_name => $plugin->[0],
        %{ $plugin->[2] },
      });
    } else {
      push @new_plugins, $plugin;
    }
  }

  @$plugins = @new_plugins;
}

sub read_expanded_config {
  my ($self, $arg) = @_;
  my ($core_config, $plugins) = $self->read_config($arg);
  $self->expand_bundles($plugins);

  return ($core_config, $plugins);
}

no Moose::Role;
1;
