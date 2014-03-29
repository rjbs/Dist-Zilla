package Dist::Zilla::Role::Releaser;
# ABSTRACT: something that makes a release of the dist

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;

=head1 DESCRIPTION

Plugins implementing this role have their C<release> method called when
releasing.  It's passed the distribution tarball to be released.

=cut

requires 'release';

1;
