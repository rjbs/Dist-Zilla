package Dist::Zilla::Plugin::MetaYAML;
# ABSTRACT: produce a META.yml
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

use Hash::Merge::Simple ();

=head1 DESCRIPTION

This plugin will add a F<META.yml> file to the distribution.

For more information on this file, see L<Module::Build::API> and
L<http://module-build.sourceforge.net/META-spec-v1.3.html>.

=cut

sub gather_files {
  my ($self, $arg) = @_;

  require Dist::Zilla::File::InMemory;
  require YAML::Tiny;

  my $meta = {
    'meta-spec' => {
      version => 1.4,
      url     => 'http://module-build.sourceforge.net/META-spec-v1.4.html',
    },
    name     => $self->zilla->name,
    version  => $self->zilla->version,
    abstract => $self->zilla->abstract,
    author   => $self->zilla->authors,
    license  => $self->zilla->license->meta_yml_name,
    requires => $self->zilla->prereq,
    generated_by => (ref $self) . ' version ' . $self->VERSION,
  };

  $meta = Hash::Merge::Simple::merge($meta, $_->metadata)
    for $self->zilla->plugins_with(-MetaProvider)->flatten;

  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'META.yml',
    content => YAML::Tiny::Dump($meta),
  });

  $self->add_file($file);
  return;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
