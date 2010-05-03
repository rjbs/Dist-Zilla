package Dist::Zilla::Role::BeforeMint;
# ABSTRACT: something that runs before minting really begins
use Moose::Role;

=head1 DESCRIPTION

Plugins implementing this role have their C<before_mint> method called
before any other plugins are consulted.

=cut

with 'Dist::Zilla::Role::Plugin';
requires 'before_mint';

no Moose::Role;
1;
