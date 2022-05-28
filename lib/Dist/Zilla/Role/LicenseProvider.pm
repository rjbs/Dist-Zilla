package Dist::Zilla::Role::LicenseProvider;
# ABSTRACT: something that provides a license for the dist

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use Dist::Zilla::Pragmas;

=head1 DESCRIPTION

Plugins implementing this role must provide a C<provide_license> method that
will be called when setting the dist's license.

If a LicenseProvider offers a license but one has already been set, an
exception will be raised.  If C<provides_license> returns undef, it will be
ignored.

=head1 REQUIRED METHODS

=head2 C<< provide_license({ copyright_holder => $holder, copyright_year => $year }) >>

Generate license object. Returned object should be an instance of
L<Software::License>.

Plugins are responsible for injecting C<$copyright_holder> and
C<$copyright_year> arguments into the license if these arguments are defined.

=cut

requires 'provide_license';

no Moose::Role;
1;
