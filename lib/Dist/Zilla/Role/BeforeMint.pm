package Dist::Zilla::Role::BeforeMint;
# ABSTRACT: something that runs before minting really begins
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;

=head1 DESCRIPTION

Plugins implementing this role have their C<before_mint> method called
before any other plugins are consulted.

=cut

requires 'before_mint';

1;
