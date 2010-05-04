package Dist::Zilla::Plugin::GenerateFile;
# ABSTRACT: build a custom file for inclusion in the dist
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::TextTemplate';

use Dist::Zilla::File::InMemory;

=head1 DESCRIPTION

This plugin adds a file to the distribution.

You can specify the content in F<dist.ini> or have it generated programmatically during run-time. Look
at the L<callback_package> and it's related attributes for more details. It is an error to specify both
the content and the callback, so please pick one!

=head2 Plain content

You can specify the content inline in the F<dist.ini> and it will be generated at run-time.

In your F<dist.ini>:

  [GenerateFile]
  filename = AuthorNotes.txt
  content = # Outlines the plan for world domination by {{$dist->name}}
  content =
  content = Item 1: Think of an idea!

=head2 Callback system

The method will be passed the L<Dist::Zilla::Plugin::GenerateFile> object, and any
args specified. It is equivalent to C<$package::$sub( $self, @args )>

In your F<dist.ini>:

  [GenerateFile]
  filename = dzil.html
  callback_package = LWP::Simple
  callback_sub = get
  callback_args = http://dzil.org
  content_nodzil = 1

=head2 Templating of the content

The content will also be run through L<Dist::Zilla>'s template processor,
so you can do stuff like C<{{$dist->name}}> in the content.

Available variables:

  * dist ( The L<Dist::Zilla> object )
  * self ( The L<Dist::Zilla::Plugin::GenerateFile> object )
  * n ( a newline )
  * t ( a tab )

=head2 Using this plugin multiple times

If you want to use this plugin multiple times, just give each section a unique name.

In your F<dist.ini>:

  [GenerateFile / file1]
  filename = foo.bar
  ...
  [GenerateFile / file2]
  filename = foo.baz
  ...

=cut

sub mvp_multivalue_args { qw(content callback_args) }

=attr filename

The filename you want to generate, required.

=cut

has filename => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

=attr content

The content you want to be put in the file. Specify it multiple times to get multi-line content!

=cut

has content => (
  is => 'ro',
  isa => 'ArrayRef',
  predicate => 'has_content',
);

=attr callback_package

The package to use when utilizing the callback mechanism to generate the content.

=cut

has callback_package => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_cb_package',
);

=attr callback_sub

The subroutine name to execute on the package for the content.

=cut

has callback_sub => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_cb_sub',
);

=attr callback_args

Extra args you want to be passed to the callback. Specify it multiple times to get
an array of args to pass to the callback.

=cut

has callback_args => (
  is => 'ro',
  isa => 'ArrayRef',
  predicate => 'has_cb_args',
);

=attr content_nodzil

Enabling this value means no L<Dist::Zilla>-specific processing
will be done on the content.

As a result, this plugin will behave a bit differently:

  - The dzil object will not be passed as the first argument to the callback
  - The returned string will not be processed by dzil's template system

=cut

has content_nodzil => (
  is => 'ro',
  isa => 'Bool',
  default => 0,
);

sub BUILD {
  my $self = shift;

  if ( ! $self->has_content and ! $self->has_cb_package ) {
    $self->log_fatal( 'GenerateFile needs content or a callback' );
  }

  if ( $self->has_cb_package and ! $self->has_cb_sub ) {
    $self->log_fatal( 'GenerateFile needs a callback_sub to call on callback_package' );
  }
}

sub gather_files {
  my ($self, $arg) = @_;

  # get the content or execute the callback?
  my $content;
  if ( $self->has_content ) {
    $content = join "\n", $self->content->flatten;
  } else {
    Class::MOP::load_class($self->callback_package);

    # TODO this needs to be rewritten to use $pkg->can but I never could get it to work...
    my $sub = \&{ $self->callback_package . '::' . $self->callback_sub };
    $self->log_fatal( "Invalid callback_sub='" . $self->callback_sub . "' in callback_package='" .
      $self->callback_package . "'" ) if ! defined &$sub;

    $content = eval {
      $sub->(
        ( $self->content_nodzil ? () : $self ),
        ( $self->has_cb_args ? $self->callback_args->flatten : () )
      );
    };
    die $@ if $@;
  }

  my $data;
  if ( ! $self->content_nodzil ) {
    $data = $self->fill_in_string(
      $content,
      {
        dist => \($self->zilla),
        self => \($self),
        n => "\n",
        t => "\t",
      },
    );
  } else {
    $data = $content;
  }

  my $file = Dist::Zilla::File::InMemory->new({
    content => $data,
    name    => $self->filename,
  });

  $self->add_file($file);
  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
