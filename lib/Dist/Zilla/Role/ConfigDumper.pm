package Dist::Zilla::Role::ConfigDumper;
# ABSTRACT: something that can dump its (public, simplified) configuration

use Moose::Role;

use Dist::Zilla::Pragmas;

use namespace::autoclean;

sub dump_config { return {}; }

1;
