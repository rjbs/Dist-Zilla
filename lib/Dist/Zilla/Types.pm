package Dist::Zilla::Types;
# ABSTRACT: dzil-specific type library

use MooseX::Types -declare => [qw(DistName)];
use MooseX::Types::Moose qw(Str);

subtype DistName,
  as Str,
  where { !/::/ },
  message { "$_ looks like a module name, not a dist name" };

1;
