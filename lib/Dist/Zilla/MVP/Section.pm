package Dist::Zilla::MVP::Section;
# ABSTRACT: a standard section in Dist::Zilla's configuration sequence

use Moose;
extends 'Config::MVP::Section';

use namespace::autoclean;

use Config::MVP::Section 2.200002; # for not-installed error

around add_value => sub {
  my ($orig, $self, $name, $value) = @_;

  if ($name =~ s/\A://) {
    if ($name eq 'version') {
      Dist::Zilla::Util->_assert_loaded_class_version_ok(
        $self->package,
        $value,
      );
    }

    return;
  }

  $self->$orig($name, $value);
};

after finalize => sub {
  my ($self) = @_;

  my ($name, $plugin_class, $arg) = (
    $self->name,
    $self->package,
    $self->payload,
  );

  my %payload = %{ $self->payload };

  $plugin_class->register_component($name, \%payload, $self);

  return;
};

__PACKAGE__->meta->make_immutable;
1;
