package Dist::Zilla::Role::FileFinder;
# ABSTRACT: something that finds files within the distribution

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use Dist::Zilla::Dialect;

use namespace::autoclean;

=head1 DESCRIPTION

A FileFinder plugin locates files within the distribution.  This role exists so
that sets of files can be easily described in one configuration section and
then used by one or more other plugin.

Plugins implementing this role must provide a C<find_files> method which will
be called with no arguments and must return an arrayref of files.  (This
arrayref should not be re-used, as it may be altered once returned.)

For example, imagine a simple glob-like FileFinder that expects configuration
like this:

  [Glob / RootModules]
  glob = *.pm

This sets up a FileFinder named "RootModules" which will contain all F<pm>
files in the root directory.

Another plugin that knows how to use FileFinder plugins might be configured
like this:

  [ModuleRelocator]
  finder = RootModules
  relocate_to = attic

Finders may operate on any rules they like, checking file size, content, name,
or other properties.  They should re-perform their "finding" on each call to
C<find_files> as the files in the distribution may have changed.

=cut

requires 'find_files';

1;
