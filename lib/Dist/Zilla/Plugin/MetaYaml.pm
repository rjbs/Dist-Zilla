package Dist::Zilla::Plugin::MetaYaml;
# ABSTRACT: produce a META.yml
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

sub gather_files {
  my ($self, $arg) = @_;

  require Dist::Zilla::File::InMemory;
  require YAML::Syck;

  my $meta = {
    name     => $self->zilla->name,
    version  => $self->zilla->version,
    abstract => $self->zilla->abstract,
    author   => $self->zilla->authors,
    license  => $self->zilla->license->meta_yml_name,
    requires => $self->zilla->prereq,
    generated_by => (ref $self) . ' version ' . $self->VERSION,
  };

  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'META.yml',
    content => YAML::Syck::Dump($meta),
  });

  $self->add_file($file);
  return;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
