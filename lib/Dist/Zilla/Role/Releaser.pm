package Dist::Zilla::Role::Releaser;
# ABSTRACT: something that makes a release of the dist

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use Dist::Zilla::Dialect;

use namespace::autoclean;

=head1 DESCRIPTION

Plugins implementing this role have their C<release> method called when
releasing.

The archive filename (the distribution tarball) is passed as the
sole argument. It is relative to the distribution root.

=cut

requires 'release';

1;
