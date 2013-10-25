package Dist::Zilla::Role::FileMunger;
# ABSTRACT: something that alters a file's destination or content
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;

use Moose::Autobox;

=head1 DESCRIPTION

A FileMunger has an opportunity to mess around with each file that will be
included in the distribution.  Each FileMunger's C<munge_files> method is
called once.  By default, this method will just call the C<munge_file> method
(note the missing terminal 's') once for each file, excluding files with an
encoding attribute of 'bytes'.

The C<munge_file> method is expected to change attributes about the file before
it is written out to the built distribution.

If you want to modify all files (including ones with an encoding of 'bytes') or
want to select a more limited set of files, you can provide your own
C<munge_files> method.

=cut

sub munge_files {
  my ($self) = @_;

  $self->log_fatal("no munge_file behavior implemented!")
    unless $self->can('munge_file');

  $self->munge_file($_)
    for grep { $_->encoding ne 'bytes' } $self->zilla->files->flatten;
}

1;
