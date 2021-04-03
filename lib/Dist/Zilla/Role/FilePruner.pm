package Dist::Zilla::Role::FilePruner;
# ABSTRACT: something that removes found files from the distribution

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

=head1 DESCRIPTION

Plugins implementing FilePruner have their C<prune_files> method called once
all the L<FileGatherer|Dist::Zilla::Role::FileGatherer> plugins have been
called.  They are expected to (optionally) remove files from the list of files
to be included in the distribution.

=cut

requires 'prune_files';

1;
