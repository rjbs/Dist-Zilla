package Dist::Zilla::Role::Stash;
# ABSTRACT: something that stores options or data for later reference

use Moose::Role;

use Dist::Zilla::Dialect;

use namespace::autoclean;

sub register_component {
  my ($class, $name, $arg, $section) = @_;

  # $self->log_debug([ 'online, %s v%s', $self->meta->name, $version ]);
  my $entry = $class->stash_from_config($name, $arg, $section);

  $section->sequence->assembler->register_stash($name, $entry);

  return;
}

sub stash_from_config {
  my ($class, $name, $arg, $section) = @_;

  my $self = $class->new($arg);
  return $self;
}

1;
