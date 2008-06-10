package Dist::Zilla::Role::TextTemplate;
# ABSTRACT: something that renders a Text::Template template string
use Moose::Role;

=head1 DESCRIPTION

Plugins implementing TextTemplate may call their own C<L</fill_in_string>>
method to render templates using L<Text::Template|Text::Template>.

=cut

use Text::Template;

=attr delim

This attribute (which can't easily be set!) is a two-element array reference
returning the Text::Template delimiters to use.  It defaults to C<{{> and
C<}}>.

=cut

# XXX: Later, add a way to set this in config. -- rjbs, 2008-06-02
has delim => (
  is   => 'ro',
  isa  => 'ArrayRef',
  lazy => 1,
  init_arg => undef,
  default  => sub { [ qw(  {{  }}  ) ] },
);

=method fill_in_string

  my $rendered = $plugin->fill_in_string($template, \%stash, \%arg);

This uses Text::Template to fill in the given template using the variables
given in the C<%stash>.  The stash becomes the HASH argument to Text::Template,
so scalars must be scalar references rather than plain scalars.

C<%arg> is dereferenced and passed in as extra arguments to Text::Template's
C<fill_in_string> routine.

=cut

sub fill_in_string {
  my ($self, $string, $stash, $arg) = @_;

  return Text::Template::fill_in_string(
    $string,
    HASH       => $stash,
    DELIMITERS => $self->delim,
    %$arg,
  );
}

no Moose::Role;
1;
