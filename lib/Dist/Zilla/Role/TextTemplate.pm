package Dist::Zilla::Role::TextTemplate;
use Moose::Role;

use Text::Template;

# XXX: Later, add a way to set this in config. -- rjbs, 2008-06-02
has delim => (
  is   => 'ro',
  isa  => 'ArrayRef',
  lazy => 1,
  init_arg => undef,
  default  => sub { [ qw(  {{  }}  ) ] },
);

sub fill_in_string {
  my ($self, $string, $stash, $arg) = @_;

  return Text::Template->fill_in_string(
    $string,
    HASH       => $stash,
    DELIMITERS => $self->delim,
    %$arg,
  );
}

no Moose::Role;
1;
