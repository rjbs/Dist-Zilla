package Dist::Zilla::Role::BeforeArchive;
# ABSTRACT: something that runs before the archive file is built

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;

=head1 DESCRIPTION

Plugins implementing this role have their C<before_archive> method
called before the archive is actually built.

=cut

requires 'before_archive';

1;
