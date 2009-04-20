package Dist::Zilla::Role::File;
# ABSTRACT: something that can act like a file
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

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

=attr install_type

This attribute may be set to something indicating where the file will be
installed.  For now, its meaning is pretty up in the air.

=cut

has install_type => (
  is => 'rw',
);

requires 'content';

no Moose::Role;
1;
