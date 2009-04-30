package Dist::Zilla::Role::FileMunger;
# ABSTRACT: something that alters a file's destination or content
use Moose::Role;
use Moose::Autobox;

=head1 DESCRIPTION

A FileMunger has an opportunity to mess around with each file that will be
included in the distribution.  Each FileMunger's C<munge_files> method is
called once.  By default, this method will just call the C<munge_file> (note
the missing terminal 's') once for each file.

This method is expected to change attributes about the file before it is
written out to the built distribution.

=cut

with 'Dist::Zilla::Role::Plugin';
requires 'munge_file';

sub munge_files {
  my ($self) = @_;

  $self->munge_file($_) for $self->zilla->files->flatten;
}

no Moose::Role;
1;
