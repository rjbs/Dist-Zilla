package Dist::Zilla::File::FromCode;
# ABSTRACT: a file whose content is (re-)built on demand
use Moose;
use Moose::Util::TypeConstraints;

use namespace::autoclean;

=head1 DESCRIPTION

This represents a file whose contents will be generated on demand from a
callback or method name.

It has one attribute, C<code>, which may be a method name (string) or a
coderef.  When the file's C<content> method is called, the code is used to
generate the content.  This content is I<not> cached.  It is recomputed every
time the content is requested.

=cut

has code => (
  is  => 'rw',
  isa => 'CodeRef|Str',
  required => 1,
);

=attr code_return_type

'text' or 'bytes'

=cut

has code_return_type => (
  is => 'ro',
  isa => enum([ qw(text bytes) ]),
  default => 'text',
);

=attr encoding

=cut

has encoding => (
    is => 'ro',
    isa => 'Str',
    default => 'UTF-8',
);

=attr content

=cut

sub content {
  my ($self) = @_;

  $self->log_fatal("cannot set content of a FromCode file") if @_ > 1;

  my $code = $self->code;
  my $result = $self->$code;

  if ( $self->code_return_type eq 'text' ) {
    return $result;
  }
  else {
    $self->_decode($result);
  }
}

=attr encoded_content

=cut

sub encoded_content {
  my ($self) = @_;

  $self->log_fatal( "cannot set encoded_content of a FromCode file" ) if @_ > 1;

  my $code = $self->code;
  my $result = $self->$code;

  if ( $self->code_return_type eq 'bytes' ) {
    return $result;
  }
  else {
    $self->_encode($result);
  }
}


with 'Dist::Zilla::Role::File';
__PACKAGE__->meta->make_immutable;
1;
