package Dist::Zilla::Plugin::MetaConfig;
# ABSTRACT: summarize Dist::Zilla configuration into distmeta
use Moose;
with 'Dist::Zilla::Role::MetaProvider';

sub metadata {
  my ($self) = @_;

  my $dump = { };

  my @plugins;
  $dump->{plugins} = \@plugins;

  my $config = $self->zilla->dump_config;
  $dump->{zilla} = {
    class   => $self->zilla->meta->name,
    version => $self->zilla->VERSION,
      (keys %$config ? (config => $config) : ()),
  };

  for my $plugin (@{ $self->zilla->plugins }) {
    my $config = $plugin->dump_config;

    push @plugins, {
      class   => $plugin->meta->name,
      name    => $plugin->plugin_name,
      version => $plugin->VERSION,
      (keys %$config ? (config => $config) : ()),
    };
  }

  return { x_Dist_Zilla => $dump };
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
