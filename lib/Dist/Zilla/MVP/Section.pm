package Dist::Zilla::MVP::Section;
use Moose;
extends 'Config::MVP::Section';
# ABSTRACT: a standard section in Dist::Zilla's configuration sequence

use Config::MVP::Section 2.200001; # for not-installed error

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
    require Version::Requirements;
    my $req = Version::Requirements->from_string_hash({
      $plugin_class => $dzil{version}
    });

    my $version = $plugin_class->VERSION;
    unless ($req->accepts_module($plugin_class => $version)) {
      # $self->assembler->log_fatal([
      confess sprintf
        "%s version (%s) not match required version: %s",
        $plugin_class,
        $version,
        $dzil{version},
      ;
      # ]);
    }
  }

  $plugin_class->register_component($name, $arg, $self);

  return;
};

1;
