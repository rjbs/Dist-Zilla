package Dist::Zilla::Types;
# ABSTRACT: dzil-specific type library

=head1 OVERVIEW

This library provides L<MooseX::Types> types for use by Dist::Zilla.  These
types are not (yet?) for public consumption, and you should not rely on them.

Dist::Zilla uses a number of types found in L<MooseX::Types::Perl>.  Maybe
that's what you want.

=cut

use MooseX::Types -declare => [qw(License OneZero YesNoStr)];
use MooseX::Types::Moose qw(Str Int);

subtype License, as class_type('Software::License');

subtype OneZero, as Str, where { $_ eq '0' or $_ eq '1' };

subtype YesNoStr, as Str, where { /\A(?:y|ye|yes)\Z/i or /\A(?:n|no)\Z/i };

coerce OneZero, from YesNoStr, via { /\Ay/i ? 1 : 0 };

1;
