package Dist::Zilla::Role::ArchiveBuilder;
# ABSTRACT: something that builds archives

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use Dist::Zilla::Pragmas;

requires 'build_archive';

=head1 DESCRIPTION

Plugins implementing this role have their C<build_archive> method called
when it is time to build the archive.

=method build_archive

This method takes three arguments, and returns a L<Path::Tiny> instance
containing the path to the archive.

=over 4

=item archive_basename

This is the name of the archive (including C<-TRIAL> if appropriate) without
the format extension (that is the C<.tar.gz> part).  The plugin implementing
this role should add the appropriate full path including extension as the
returned L<Path::Tiny> instance.  Not including the extension allows the
plugin to choose its own format.

=item built_in

This is a L<Path::Tiny> where the distribution has been built.

=item dist_basename

This method will return the dist's basename (e.g. C<Dist-Name-1.01> as a
L<Path::Tiny>.  The basename is used as the top-level directory in the
tarball.  It does not include C<-TRIAL>, even if building a trial dist.

=back

=cut

no Moose::Role;
1;
