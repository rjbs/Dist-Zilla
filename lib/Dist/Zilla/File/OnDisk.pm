package Dist::Zilla::File::OnDisk;
# ABSTRACT: a file that comes from your filesystem
use Moose;

use namespace::autoclean;

=head1 DESCRIPTION

This represents a file stored on disk.  Its C<content> attribute is read from
the originally given file name when first read, but is then kept in memory and
may be altered by plugins.

=cut

has content => (
  is  => 'rw',
  isa => 'Str',
  lazy => 1,
  default => sub { shift->_read_file },
);

has _original_name => (
  is  => 'ro',
  isa => 'Str',
  init_arg => undef,
);

sub BUILD {
  my ($self) = @_;
  $self->{_original_name} = $self->name;
}

sub _read_file {
  my ($self) = @_;

  my $fname = $self->_original_name;
  open my $fh, '<', $fname or die "can't open $fname for reading: $!";

  # This is needed or \r\n is filtered to be just \n on win32.
  # ...and always read in decoded characters, not encoded octets.
  binmode $fh, ':raw:utf8';

  my $content = do { local $/; <$fh> };
}

with 'Dist::Zilla::Role::File';

__PACKAGE__->meta->make_immutable;
1;
