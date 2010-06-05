package Dist::Zilla::File::InMemory;
# ABSTRACT: a file that you build entirely in memory
use Moose;

=head1 DESCRIPTION

This represents a file created in memory -- it's not much more than a glorified
string.  It has a read/write C<content> attribute that holds the octets that
will be written to disk.

=cut

has content => (
  is  => 'rw',
  isa => 'Str',
  required => 1,
);

with 'Dist::Zilla::Role::File';
__PACKAGE__->meta->make_immutable;
no Moose;
1;
