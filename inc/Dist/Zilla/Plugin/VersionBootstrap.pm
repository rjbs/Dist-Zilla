package inc::Dist::Zilla::Plugin::VersionBootStrap;
use Moose;
with 'Dist::Zilla::Role::BeforeBuild';

sub before_build {
  my ($self, $arg) = @_;

  return unless $self->zilla->name eq 'Dist-Zilla';
  $Dist::Zilla::VERSION = $self->zilla->version;
}

no Moose;
1;
