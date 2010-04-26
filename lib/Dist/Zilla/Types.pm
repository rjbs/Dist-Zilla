package Dist::Zilla::Types;
# ABSTRACT: dzil-specific type library

use MooseX::Types -declare => [qw(DistName License ModuleName VersionStr)];
use MooseX::Types::Moose qw(Str);

use Params::Util qw(_CLASS);

use version 0.82;

subtype ModuleName,
  as Str,
  where   { _CLASS($_) },
  message { "$_ is not a valid module name" };

subtype DistName,
  as Str,
  where   { return if /:/; (my $str = $_) =~ s/-/::/; _CLASS($str) },
  message {
    /::/
    ? "$_ looks like a module name, not a dist name"
    : "$_ is not a valid dist name"
  };

subtype License,
  as class_type('Software::License');

subtype VersionStr,
  as Str,
  where { version::is_lax($_) },
  message { "$_ is not a valid version string" };

1;
