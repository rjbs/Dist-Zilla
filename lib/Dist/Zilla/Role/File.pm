package Dist::Zilla::Role::File;
# ABSTRACT: something that can act like a file
use Moose::Role;

use Moose::Util::TypeConstraints;

use namespace::autoclean;

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

requires 'content';

1;
