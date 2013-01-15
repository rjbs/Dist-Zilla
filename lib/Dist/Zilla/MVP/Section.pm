package Dist::Zilla::MVP::Section;
use Moose;
extends 'Config::MVP::Section';
# ABSTRACT: a standard section in Dist::Zilla's configuration sequence

use namespace::autoclean;

use Config::MVP::Section 2.200002; # for not-installed error

use Moose::Autobox;

after finalize => sub {
  my ($self) = @_;

  my ($name, $plugin_class, $arg) = (
    $self->name,
    $self->package,
    $self->payload,
  );

  my %payload = %{ $self->payload };

  my %dzil;
  $dzil{$_} = delete $payload{":$_"} for grep { s/\A:// } keys %payload;

  if (defined $dzil{version}) {
    Dist::Zilla::Util->_assert_loaded_class_version_ok(
      $plugin_class,
      $dzil{version},
    );
  }

  $plugin_class->register_component($name, \%payload, $self);

  return;
};

__PACKAGE__->meta->make_immutable;
1;
