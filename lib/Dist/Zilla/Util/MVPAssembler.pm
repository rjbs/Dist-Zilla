package Dist::Zilla::Util::MVPAssembler;
use Moose;
extends 'Config::MVP::Assembler';
# ABSTRACT: Dist::Zilla-specific subclass of Config::MVP::Assembler

sub expand_package {
  my $str = Dist::Zilla::Util->expand_config_package_name($_[1]);
  return $str;
}

after end_section => sub {
  my ($self) = @_;

  my $seq = $self->sequence;

  my ($last) = ($seq->sections)[-1];
  return unless $last->package;

  {
    local $@;
    return unless eval {
      $last->package->does('Dist::Zilla::Role::PluginBundle');
    };
  }

  $seq->delete_section($last->name);

  my @bundle_config = $last->package->bundle_config({
    plugin_name => $last->name,
    %{ $last->payload },
  });

  for my $plugin (@bundle_config) {
    my ($name, $package, $payload) = @$plugin;

    my $section = $self->section_class->new({
      name    => $name,
      package => $package,
    });

    Carp::confess('bundles may not include bundles')
      if $package->does('Dist::Zilla::Role::PluginBundle');

    # XXX: Clearly this is a hack. -- rjbs, 2009-08-24
    for my $name (keys %$payload) {
      my @v = ref $payload->{$name} ? @{$payload->{$name}} : $payload->{$name};
      $section->add_value($name => $_) for @v;
    }

    $self->sequence->add_section($section);
  }
};

sub expand_bundles {
  my ($self, $plugins) = @_;

  my @new_plugins;

  for my $plugin (@$plugins) {
    if (eval { $plugin->[1]->does('Dist::Zilla::Role::PluginBundle') }) {
    } else {
      push @new_plugins, $plugin;
    }
  }

  @$plugins = @new_plugins;
}

no Moose;
1;
