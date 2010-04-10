package Dist::Zilla::File::FromCode;
# ABSTRACT: a file whose content is (re-)built on demand
use Moose;

=head1 DESCRIPTION

This represents a file whose contents will be generated on demand from a
callback or method name.

=cut

has code => (
  is  => 'rw',
  isa => 'CodeRef|Str',
  required => 1,
);

sub content {
  my ($self) = @_;

  confess "cannot set content of a FromCode file" if @_ > 1;

  my $code = $self->code;
  return $self->$code;
}

with 'Dist::Zilla::Role::File';
__PACKAGE__->meta->make_immutable;
no Moose;
1;
