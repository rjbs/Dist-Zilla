package Dist::Zilla::Role::VersionProvider;
# ABSTRACT: something that provides a version number for the dist

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

Plugins implementing this role must provide a C<provide_version> method that
will be called when setting the dist's version.

If a VersionProvider offers a version but one has already been set, an
exception will be raised.  If C<provides_version> returns undef, it will be
ignored.

=cut

requires 'provide_version';

1;

=head1 SEE ALSO

Core Dist::Zilla plugins implementing this role:
L<AutoVersion|Dist::Zilla::Plugin::AutoVersion>.

=cut
