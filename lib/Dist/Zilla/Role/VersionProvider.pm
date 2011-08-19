package Dist::Zilla::Role::VersionProvider;
# ABSTRACT: something that provides a version number for the dist
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;

=head1 DESCRIPTION

Plugins implementing this role must provide a C<provide_version> method that
will be called when setting the dist's version.

If a VersionProvider offers a version but one has already been set, an
exception will be raised.  If C<provides_version> returns undef, it will be
ignored.

=cut

requires 'provide_version';

1;
