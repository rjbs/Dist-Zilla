package Dist::Zilla::File::InMemory;
# ABSTRACT: a file that you build entirely in memory
use Moose;
with 'Dist::Zilla::Role::File';

=head1 DESCRIPTION

This represents a file created in memory -- it's not much more than a glorified
string.

=cut

has content => (
  is  => 'rw',
  isa => 'Str',
  required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;
