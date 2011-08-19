package Dist::Zilla::Role::Stash::Authors;
use Moose::Role;
with 'Dist::Zilla::Role::Stash';
# ABSTRACT: a stash that provides a list of author strings

use namespace::autoclean;

=head1 OVERVIEW

An Authors stash must provide an C<authors> method that returns an arrayref of
author strings, generally in the form "Name <email>".

=cut

requires 'authors';

1;
