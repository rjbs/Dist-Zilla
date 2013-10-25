package Dist::Zilla::File::OnDisk;
# ABSTRACT: a file that comes from your filesystem
use Moose;

use Path::Tiny;

use namespace::autoclean;

with 'Dist::Zilla::Role::MutableFile', 'Dist::Zilla::Role::StubBuild';

=head1 DESCRIPTION

This represents a file stored on disk.  Its C<content> attribute is read from
the originally given file name when first read, but is then kept in memory and
may be altered by plugins.

=cut

has _original_name => (
  is  => 'ro',
  writer => '_set_original_name',
  isa => 'Str',
  init_arg => undef,
);

after 'BUILD' => sub {
  my ($self) = @_;
  $self->_set_original_name( $self->name );
};

sub _build_encoded_content {
  my ($self) = @_;
  return path($self->_original_name)->slurp_raw;
}

sub _build_content_source { return "encoded_content" }

# should never be called, as content will always be generated from
# encoded content
sub _build_content { die "shouldn't reach here" }

__PACKAGE__->meta->make_immutable;
1;
