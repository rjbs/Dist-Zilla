package Dist::Zilla::Plugin::MetaJSON;
# ABSTRACT: produce a META.json
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

use Hash::Merge::Simple ();

=head1 DESCRIPTION

This plugin will add a F<META.json> file to the distribution.

This file is meant to replace the old-style F<META.yml>.  For more information
on this file, see L<Module::Build::API> and
L<http://module-build.sourceforge.net/META-spec-v1.3.html>.

=cut

sub gather_files {
  my ($self, $arg) = @_;

  require Dist::Zilla::File::InMemory;
  require JSON;

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
    name    => 'META.json',
    content => JSON->new->ascii(1)->pretty->encode($meta) . "\n",
  });

  $self->add_file($file);
  return;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
