package Dist::Zilla::Role::StubBuild;
# ABSTRACT: provides an empty BUILD methods

use Moose::Role;

use Dist::Zilla::Pragmas;

sub BUILD {}

no Moose::Role;
1;
