package Dist::Zilla::Role::Stash::Login;
use Moose::Role;
with 'Dist::Zilla::Role::Stash';
# ABSTRACT: a stash with username/password credentials

=head1 OVERVIEW

A Login stash must provide a C<username> and C<password> method.

=cut

requires 'username';
requires 'password';

1;
