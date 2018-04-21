package Dist::Zilla::Role::InstallTool;
# ABSTRACT: something that creates an install program for a dist

use Moose::Role;
with qw(
  Dist::Zilla::Role::Plugin
  Dist::Zilla::Role::FileInjector
);

use Dist::Zilla::Dialect;

use namespace::autoclean;

=head1 DESCRIPTION

Plugins implementing InstallTool have their C<setup_installer> method called to
inject files after all other file injection and munging has taken place.
They're expected to produce files needed to make the distribution
installable, like F<Makefile.PL> or F<Build.PL> and add them with the
C<add_file> method provided by L<Dist::Zilla::Role::FileInjector>, which is
also composed by this role.

=cut

requires 'setup_installer';

1;
