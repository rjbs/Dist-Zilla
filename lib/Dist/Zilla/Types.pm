package Dist::Zilla::Types;
# ABSTRACT: dzil-specific type library

use MooseX::Types -declare => [qw(License)];
use MooseX::Types::Moose qw(Str);

subtype License, as class_type('Software::License');

1;
