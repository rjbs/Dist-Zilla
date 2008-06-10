package Dist::Zilla::Role::InstallTool;
# ABSTRACT: something that creates an install program for a dist
use Moose::Role;
use Moose::Autobox;

=head1 DESCRIPTION

Plugins implementing InstallTool have their C<setup_installer> method called to
inject files after all other file injection and munging has taken place.
They're expected to write out files needed to make the distribution
installable, like F<Makefile.PL> or F<Build.PL>.

=cut

with 'Dist::Zilla::Role::Plugin';
with 'Dist::Zilla::Role::FileInjector';
requires 'setup_installer';

no Moose::Role;
1;
