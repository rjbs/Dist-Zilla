package Dist::Zilla::Role::Stash::Login;
# ABSTRACT: a stash with username/password credentials

use Moose::Role;
with 'Dist::Zilla::Role::Stash';

use namespace::autoclean;

=head1 OVERVIEW

A Login stash must provide a C<username> and C<password> method.

=cut

requires 'username';
requires 'password';

1;
