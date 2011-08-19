package Dist::Zilla::Role::AfterMint;
# ABSTRACT: something that runs after minting is mostly complete
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;

=head1 DESCRIPTION

Plugins implementing this role have their C<after_mint> method called once all
the files have been written out.  It is passed a hashref with the following
data:

  mint_root - the directory in which the dist was minted

=cut

requires 'after_mint';

1;
