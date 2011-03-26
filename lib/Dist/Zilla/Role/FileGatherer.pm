package Dist::Zilla::Role::FileGatherer;
# ABSTRACT: something that gathers files into the distribution
use Moose::Role;
with qw/Dist::Zilla::Role::Plugin Dist::Zilla::Role::FileInjector/;

use Moose::Autobox;

=head1 DESCRIPTION

A FileGatherer plugin is a special sort of
L<FileInjector|Dist::Zilla::Role::FileInjector> that runs early in the build
cycle, finding files to include in the distribution.  It is expected to call
its C<add_file> method to add one or more files to inclusion.

Plugins implementing FileGatherer must provide a C<gather_files> method, which
will be called during the build process.

=cut

requires 'gather_files';

no Moose::Role;
1;
