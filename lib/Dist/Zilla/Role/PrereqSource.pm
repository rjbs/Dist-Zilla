package Dist::Zilla::Role::PrereqSource;
# ABSTRACT: something that registers prerequisites

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

=head1 DESCRIPTION

PrereqSource plugins have a C<register_prereqs> method that should register
prereqs with the Dist::Zilla object.

=cut

requires 'register_prereqs';

1;
