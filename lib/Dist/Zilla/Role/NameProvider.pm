package Dist::Zilla::Role::NameProvider;
# ABSTRACT: something that provides a name for the dist
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

=head1 DESCRIPTION

Plugins implementing this role must provide a C<provide_name> method that
will be called when setting the dist's name.

If a NameProvider offers a name but one has already been set, an
exception will be raised.  If C<provide_name> returns undef, it will be
ignored.

=cut

requires 'provide_name';

no Moose::Role;
1;
