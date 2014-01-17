package Dist::Zilla::Plugin::GatherDir::Template;
# ABSTRACT: gather all the files in a directory and use them as templates

use Moose;
extends 'Dist::Zilla::Plugin::GatherDir';
with 'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::TextTemplate';

use namespace::autoclean;

use autodie;
use Moose::Autobox;
use Path::Tiny;

=head1 DESCRIPTION

This is a subclass of the L<GatherDir|Dist::Zilla::Plugin::GatherDir>
plugin.  It works just like its parent class, except that each
gathered file is processed through L<Text::Template> at file munging time.

The variables C<$plugin> and C<$dist> will be provided to the
template, set to the GatherDir::Template plugin and the Dist::Zilla
object, respectively.

It is meant to be used when minting dists with C<dzil new>, but could be used
in building existing dists, too.

=head1 SEE ALSO

L<[GenerateFile]|Dist::Zilla::Plugin::GenerateFile> likewise
generates a file from a template, but the template comes from the plugin
configuration in F<dist.ini>, rather than in a separate file.

=cut

sub munge_files {
  my ($self) = @_;

  $self->munge_file($_) for $self->_files->flatten;
}

sub munge_file {
  my ($self, $file) = @_;

  # we do this in a separate phase rather than in gather_files because at that
  # time, we don't yet know the file content's encoding
  $file->content(
    $self->fill_in_string(
      $file->content,
      {
        dist   => \($self->zilla),
        plugin => \($self),
      },
    ),
  );
}

__PACKAGE__->meta->make_immutable;
1;
