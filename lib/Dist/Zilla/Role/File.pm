package Dist::Zilla::Role::File;
# ABSTRACT: something that can act like a file
use Moose::Role;

use Moose::Util::TypeConstraints;
use Try::Tiny;

use namespace::autoclean;

with 'Dist::Zilla::Role::StubBuild';

=head1 DESCRIPTION

This role describes a file that may be written into the shipped distribution.

=attr name

This is the name of the file to be written out.

=cut

has name => (
  is   => 'rw',
  isa  => 'Str', # Path::Class::File?
  required => 1,
);

=attr added_by

This is a string describing when and why the file was added to the
distribution.  It will generally be set by a plugin implementing the
L<FileInjector|Dist::Zilla::Role::FileInjector> role.

=cut

has added_by => (
  is => 'ro',
  writer => '_set_added_by',
  isa => 'Str',
);

=attr mode

This is the mode with which the file should be written out.  It's an integer
with the usual C<chmod> semantics.  It defaults to 0644.

=cut

my $safe_file_mode = subtype(
  as 'Int',
  where   { not( $_ & 0002) },
  message { "file mode would be world-writeable" }
);

has mode => (
  is      => 'rw',
  isa     => $safe_file_mode,
  default => 0644,
);

requires 'encoding';
requires 'has_encoding';
requires 'content';
requires 'encoded_content';

=method is_bytes

Returns true if the C<encoding> is bytes.  When true, accessing
C<content> will be an error.

=cut

sub is_bytes {
    my ($self) = @_;
    return $self->encoding eq 'bytes';
}

sub _encode {
  my ($self, $text) = @_;
  my $enc = $self->encoding;
  if ( $self->is_bytes ) {
    return $text; # XXX hope you were right that it really was bytes
  }
  else {
    require Encode;
    my $bytes =
      try { Encode::encode($enc, $text, Encode::FB_CROAK()) }
      catch { $self->_throw("encode $enc" => $_) };
    return $bytes;
  }
}

sub _decode {
  my ($self, $bytes) = @_;
  my $enc = $self->encoding;
  if ( $self->is_bytes ) {
    $self->_throw(decode => "Can't decode text from 'bytes' encoding");
  }
  else {
    require Encode;
    my $text =
      try { Encode::decode($enc, $bytes, Encode::FB_CROAK()) }
      catch { $self->_throw("decode $enc" => $_) };
    return $text;
  }
}

sub _throw {
  my ($self, $op, $msg) = @_;
  my ($name, $added_by) = map {; $self->$_ } qw/name added_by/;
  confess(
    "Could not $op $name; $added_by; error was: $msg"
  );
}

1;
