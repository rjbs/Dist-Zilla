package Dist::Zilla::Role::File;
# ABSTRACT: something that can act like a file

use Moose::Role;

use Dist::Zilla::Dialect;

use Dist::Zilla::Types qw(_Filename);
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
  isa  => _Filename,
  required => 1,
);

=attr added_by

This is a list of strings describing when and why the file was added
to the distribution and when it was updated (its content, filename, or other attributes).  It will
generally be updated by a plugin implementing the
L<FileMunger|Dist::Zilla::Role::FileMunger> role.  Its accessor will return
the list of strings, concatenated with C<'; '>.

=cut

has added_by => (
  isa => 'ArrayRef[Str]',
  lazy => 1,
  default => sub { [] },
  traits => ['Array'],
  init_arg => undef,
  handles => {
    _push_added_by => 'push',
    added_by => [ join => '; ' ],
  },
);

around name => sub {
  my $orig = shift;
  my $self = shift;
  if (@_) {
    my ($pkg, $line) = $self->_caller_of('name');
    $self->_push_added_by(sprintf("filename set by %s (%s line %s)", $self->_caller_plugin_name, $pkg, $line));
  }
  return $self->$orig(@_);
};

sub _caller_of {
  my ($self, $function) = @_;

  for (my $level = 1; $level < 50; ++$level)
  {
    my @frame = caller($level);
    last if not defined $frame[0];
    return ( (caller($level))[0,2] ) if $frame[3] =~ m/::${function}$/;
  }
  return 'unknown', '0';
}

sub _caller_plugin_name {
  my $self = shift;

  for (my $level = 1; $level < 50; ++$level)
  {
    my @frame = caller($level);
    last if not defined $frame[0];
    return $1 if $frame[0] =~ m/^Dist::Zilla::Plugin::(.+)$/;
  }
  return 'unknown';
}

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

    # Okay, look, buddy…  If you're using a BOM on UTF-8, that's fine.  You can
    # use it.  You're just not going to get it back.  If we don't do this, the
    # sequence of events will be:
    # * read file from UTF-8-BOM file on disk
    # * end up with FEFF as first character of file
    # * pass file content to PPI
    # * PPI blows up
    #
    # I'm not going to try to account for the BOM and add it back.  It's awful!
    #
    # Meanwhile, if you're using UTF-16, you can get the BOM handled by picking
    # the right encoding type, I think. -- rjbs, 2016-04-24
    $enc =~ /^utf-?8$/i && $text =~ s/\A\x{FEFF}//;

    return $text;
  }
}

sub _throw {
  my ($self, $op, $msg) = @_;
  my ($name, $added_by) = map {; $self->$_ } qw/name added_by/;
  confess(
    "Could not $op $name; $added_by; error was: $msg; maybe you need the [Encoding] plugin to specify an encoding"
  );
}

1;
