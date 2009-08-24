package Dist::Zilla::Config;
use Moose::Role;
# ABSTRACT: stored configuration loader role

use Dist::Zilla::Util::MVPAssembler;

=head1 DESCRIPTION

The config role provides some helpers for writing a configuration loader using
the L<Config::MVP|Config::MVP> system to load and validate its configuration.

=attr assembler

The L<assembler> attribute must be a Config::MVP::Assembler, has a sensible
default that will handle the standard needs of a config loader.  Namely, it
will be pre-loaded with a starting section for root configuration.  That
starting section will alias C<author> to C<authors> and will set that up as a
multivalue argument.

=cut

has assembler => (
  is   => 'ro',
  isa  => 'Config::MVP::Assembler',
  lazy => 1,
  default => sub {
    my $assembler = Dist::Zilla::Util::MVPAssembler->new;

    my $root = $assembler->section_class->new({
      name => '_',
      aliases => { author => 'authors' },
      multivalue_args => [ qw(authors) ],
    });

    $assembler->sequence->add_section($root);

    return $assembler;
  }
);


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
