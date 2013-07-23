package Dist::Zilla::Role::CorePlugin;
# ABSTRACT: a plugin that ships with Dist-Zilla
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

before register_component => sub {
  my ($self) = @_;
  my $p_version = $self->VERSION;
  my $z_version = $self->zilla->VERSION;

  return if ! (defined $p_version or defined $z_version);

  if (
    (defined $p_version xor defined $z_version)
    or $p_version ne $z_version
  ) {
    my $p_str = defined $p_version ? $p_version : '(undef)'; # XXX 5.10.0
    my $z_str = defined $z_version ? $z_version : '(undef)';
    $self->log_fatal("CorePlugin version $p_str does not match Dist::Zilla version $z_str");
  }
};

1;
