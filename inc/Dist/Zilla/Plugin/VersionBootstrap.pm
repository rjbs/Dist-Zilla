package inc::Dist::Zilla::Plugin::VersionBootstrap;
# ABSTRACT: set Dist::Zilla::* $VERSION during Dist-Zilla dzilling
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::BeforeBuild';

sub before_build {
  my ($self, $arg) = @_;

  return unless $self->zilla->name eq 'Dist-Zilla';
  $Dist::Zilla::VERSION = $self->zilla->version;

  for my $plugin ($self->zilla->plugins->flatten) {
    my $plugin_class = ref $plugin;
    no strict 'refs';
    ${"$plugin_class\::VERSION"} = $self->zilla->version
      unless defined ${"$plugin_class\::VERSION"};
  }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
