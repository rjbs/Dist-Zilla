package Dist::Zilla::Role::Stash::Login;
# ABSTRACT: a stash with username/password credentials

use Moose::Role;
with 'Dist::Zilla::Role::Stash';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

=head1 OVERVIEW

A Login stash must provide a C<username> and C<password> method.

=cut

requires 'username';
requires 'password';

1;
