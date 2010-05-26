package Dist::Zilla::MVP::Section;
use Moose;
extends 'Config::MVP::Section';

use Moose::Autobox;

after finalize => sub {
  my ($self) = @_;

  my $zilla = $self->sequence->assembler->zilla;

  my ($name, $plugin_class, $arg) = (
    $self->name,
    $self->package,
    $self->payload,
  );

  return unless $plugin_class->does('Dist::Zilla::Role::Plugin');

  $zilla->log_fatal("$name arguments attempted to override plugin name")
    if defined $arg->{plugin_name};

  $zilla->log_fatal("$name arguments attempted to override plugin name")
    if defined $arg->{zilla};

  my $plugin = $plugin_class->new(
    $arg->merge({
      plugin_name => $name,
      zilla       => $zilla,
    }),
  );

  my $version = $plugin->VERSION || 0;

  $plugin->log_debug([ 'online, %s v%s', $plugin->meta->name, $version ]);

  $zilla->plugins->push($plugin);
};

1;
