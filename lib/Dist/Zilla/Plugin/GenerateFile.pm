package Dist::Zilla::Plugin::GenerateFile;
# ABSTRACT: build a custom file from only the plugin configuration

use Moose;
with (
  'Dist::Zilla::Role::FileGatherer',
  'Dist::Zilla::Role::TextTemplate',
);

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

use Dist::Zilla::File::InMemory;

=head1 SYNOPSIS

In your F<dist.ini>:

  [GenerateFile]
  filename    = todo/{{ $dist->name }}-master-plan.txt
  name_is_template = 1
  content_is_template = 1
  content = # Outlines the plan for world domination by {{$dist->name}}
  content =
  content = Item 1: Think of an idea!
  content = Item 2: ?
  content = Item 3: Profit!

=head1 DESCRIPTION

This plugin adds a file to the distribution.

You can specify the content, as a sequence of lines, in your configuration.
The specified filename and content might be literals or might be L<Text::Template>
templates.

=head2 Templating of the content

If you provide C<content_is_template> (or C<is_template>) parameter of C<"1">, the
content will be run through L<Text::Template>.  The variables C<$plugin> and
C<$dist> will be provided, set to the [GenerateFile] plugin and the L<Dist::Zilla>
object respectively.

If you provide a C<name_is_template> parameter of "1", the filename will be run
through L<Text::Template>.  The variables C<$plugin> and C<$dist> will be
provided, set to the [GenerateFile] plugin and the L<Dist::Zilla> object
respectively.

=cut

sub mvp_aliases { +{ is_template => 'content_is_template' } }

sub mvp_multivalue_args { qw(content) }

=attr filename

This attribute names the file you want to generate.  It is required.

=cut

has filename => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

=attr content

The C<content> attribute is an arrayref of lines that will be joined together
with newlines to form the file content.

=cut

has content => (
  is  => 'ro',
  isa => 'ArrayRef',
);

=attr content_is_template, is_template

This attribute is a bool indicating whether or not the content should be
treated as a Text::Template template.  By default, it is false.

=cut

has content_is_template => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

=cut

=attr name_is_template

This attribute is a bool indicating whether or not the filename should be
treated as a Text::Template template.  By default, it is false.

=cut

has name_is_template => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

sub gather_files {
  my ($self, $arg) = @_;

  my $file = Dist::Zilla::File::InMemory->new({
    name    => $self->_filename,
    content => $self->_content,
  });

  $self->add_file($file);
  return;
}

sub _content {
  my $self = shift;

  my $content = join "\n", @{ $self->content };
  $content .= qq{\n};

  if ($self->content_is_template) {
    $content = $self->fill_in_string(
      $content,
      {
        dist   => \($self->zilla),
        plugin => \($self),
      },
    );
  }

  return $content;
}

sub _filename {
  my $self = shift;

  my $filename = $self->filename;

  if ($self->name_is_template) {
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
