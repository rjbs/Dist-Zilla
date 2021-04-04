package Dist::Zilla::Role::BeforeMint;
# ABSTRACT: something that runs before minting really begins

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

Plugins implementing this role have their C<before_mint> method called
before any other plugins are consulted.

=cut

requires 'before_mint';

1;
