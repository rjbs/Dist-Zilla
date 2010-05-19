package Dist::Zilla::Types;
# ABSTRACT: dzil-specific type library

=head1 OVERVIEW

This library provides L<MooseX::Types> types for use by Dist::Zilla.  These
types are not (yet?) for public consumption, and you should not rely on them.

Dist::Zilla uses a number of types found in L<MooseX::Types::Perl>.  Maybe
that's what you want.

=cut

use MooseX::Types -declare => [qw(License)];
use MooseX::Types::Moose qw(Str);

subtype License, as class_type('Software::License');

1;
