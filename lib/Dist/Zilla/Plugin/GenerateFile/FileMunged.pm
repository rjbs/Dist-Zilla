package Dist::Zilla::Plugin::GenerateFile::FileMunged;
# ABSTRACT: build a custom file with custom filename from only the plugin configuration
use Moose;
use Moose::Autobox;

extends 'Dist::Zilla::Plugin::GenerateFile';

use namespace::autoclean;

use Dist::Zilla::File::InMemory;

=head1 SYNOPSIS

In your F<dist.ini>:

  [GenerateFile::FileMunged]
  filename    = module_share/{{ $dist->name }}/config.ini
  is_template = 1
  content = # Configuration for {{$dist->name}}
  content =
  content = item1 = foo
  content = item2 = bar
  content = item2 = baz

=head1 DESCRIPTION

This plugin adds a file to the distribution.

You can specify the content, as a sequence of lines, in your configuration.
The specified content might be literal, or might be a Text::Template template.

=head2 Templating of the filename and content

If you provide a C<is_template> parameter of "1", both the filename and content
will also be run through Text::Template.  The variables C<$plugin> and C<$dist>
will be provided, set to the GenerateFile plugin and the Dist::Zilla object
respectively.

(Note that this plugin behaves just like L<Dist::Zilla::Plugin::GenerateFile>,
except the filename is templated as well as the content.  If is_template=0, the
plugins behave identically.

=cut

=attr filename

This attribute names the file you want to generate.  It is required.

=attr content

The C<content> attribute is an arrayref of lines that will be joined together
with newlines to form the file content.

=attr is_template

This attribute is a bool indicating whether or not the filename and content
should be treated as Text::Template templates.  By default, it is false.

=cut

sub gather_files {
  my ($self, $arg) = @_;

  my $file = Dist::Zilla::File::InMemory->new({
    name    => $self->_filename,
    content => $self->_content,
  });

  $self->add_file($file);
  return;
}

sub _filename
{
  my $self = shift;

  my $filename = $self->filename;

  if ($self->is_template) {
    $filename = $self->fill_in_string(
      $filename,
      {
        dist   => \($self->zilla),
        plugin => \($self),
      },
    );
  }

  return $filename;
}

__PACKAGE__->meta->make_immutable;
1;
