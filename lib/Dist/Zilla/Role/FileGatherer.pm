package Dist::Zilla::Role::FileGatherer;
use Moose::Autobox;
# ABSTRACT: something that gathers files into the distribution
use Moose::Role;

=head1 DESCRIPTION

A FileGatherer plugin is a special sort of
L<FileInjector|Dist::Zilla::Role::FileInjector> that runs early in the build
cycle, finding files to include in the distribution.  It is expected to call
its C<add_file> method to add one or more files to inclusion.

=cut

with 'Dist::Zilla::Role::Plugin';
with 'Dist::Zilla::Role::FileInjector';
requires 'gather_files';

no Moose::Role;
1;
