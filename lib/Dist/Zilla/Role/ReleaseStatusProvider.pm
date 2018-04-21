package Dist::Zilla::Role::ReleaseStatusProvider;
# ABSTRACT: something that provides a release status for the dist

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use Dist::Zilla::Dialect;

use namespace::autoclean;

=head1 DESCRIPTION

Plugins implementing this role must provide a C<provide_release_status>
method that will be called when setting the dist's version.

If C<provides_release_status> returns undef, it will be ignored.

=cut

requires 'provide_release_status';

1;

=head1 SEE ALSO

Core Dist::Zilla plugins implementing this role:
L<AutoVersion|Dist::Zilla::Plugin::AutoVersion>.

=cut
