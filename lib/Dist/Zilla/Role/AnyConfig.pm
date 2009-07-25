package Dist::Zilla::Role::AnyConfig;
# ABSTRACT: something that Dist::Zilla::Config::Any can look at
use Moose::Role;

=head1 DESCRIPTION

=cut

requires 'default_extension';

no Moose::Role;
1;
