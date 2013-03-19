package Dist::Zilla::Role::AbstractProvider;
# ABSTRACT: something that provides an abstract for the dist
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

=head1 DESCRIPTION

Plugins implementing this role must provide a C<provide_abstract> method that
will be called when setting the dist's abstract.

If an AbstractProvider offers an abstract but one has already been set, an
exception will be raised.  If C<provide_abstract> returns undef, it will be
ignored.

=cut

requires 'provide_abstract';

no Moose::Role;
1;
