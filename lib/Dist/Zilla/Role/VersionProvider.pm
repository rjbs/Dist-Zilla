package Dist::Zilla::Role::VersionProvider;
# ABSTRACT: something that provides a version number for the dist
use Moose::Role;

=head1 DESCRIPTION

Plugins implementing this role must provide a C<provide_version> method that
will be called when setting the dist's version.

If a VersionProvider offers a version but one has already been set, an
exception will be raised.  If C<provides_version> returns undef, it will be
ignored.

=cut

with 'Dist::Zilla::Role::Plugin';
requires 'provide_version';

no Moose::Role;
1;
