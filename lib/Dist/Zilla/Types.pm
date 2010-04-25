package Dist::Zilla::Types;
# ABSTRACT: dzil-specific type library

use MooseX::Types -declare => [qw(DistName License VersionStr)];
use MooseX::Types::Moose qw(Str);

use version 0.82;

subtype DistName,
  as Str,
  where { !/::/ },
  message { "$_ looks like a module name, not a dist name" };

subtype License,
  as class_type('Software::License');

subtype VersionStr,
  as Str,
  where { version::is_lax($_) },
  message { "$_ is not a valid version string" };

1;
