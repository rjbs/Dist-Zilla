package Dist::Zilla::Role::ConfigDumper;
# ABSTRACT: something that can dump its (public, simplified) configuraiton
use Moose::Role;

use namespace::autoclean;

sub dump_config { return {}; }

1;
