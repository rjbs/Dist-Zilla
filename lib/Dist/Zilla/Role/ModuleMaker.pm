package Dist::Zilla::Role::ModuleMaker;
# ABSTRACT: something that injects module files into the dist
use Moose::Role;
with qw(
  Dist::Zilla::Role::Plugin
  Dist::Zilla::Role::FileInjector
);

use namespace::autoclean;

=head1 DESCRIPTION

Plugins implementing this role have their C<make_module> method called for each
module requesting creation by the plugin with this name.  It is passed a
hashref with the following data:

  name - the name of the module to make (a MooseX::Types::Perl::ModuleName)

Classes composing this role also compose
L<FileInjector|Dist::Zilla::Role::FileInjector> and are expected to inject a
file for the module being created.

=cut

requires 'make_module';

1;
