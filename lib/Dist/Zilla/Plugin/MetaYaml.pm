package Dist::Zilla::Plugin::MetaYaml;
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileWriter';

use Dist::Zilla::File::InMemory;

use YAML::Syck ();

sub write_files {
  my ($self, $arg) = @_;

  my $meta = {
    name     => $self->zilla->name,
    version  => $self->zilla->version,
    abstract => '...', # XXX figure this out -- rjbs, 2008-06-01
    author   => $self->zilla->authors,
    license  => $self->zilla->license->meta_yml_name,
    requires => $self->zilla->prereq,
    generated_by => (ref $self) . ' version ' . $self->VERSION,
  };

  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'META.yml',
    content => YAML::Syck::Dump($meta),
  });

  return [ $file ];
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
