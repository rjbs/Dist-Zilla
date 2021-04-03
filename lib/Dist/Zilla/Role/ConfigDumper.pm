package Dist::Zilla::Role::ConfigDumper;
# ABSTRACT: something that can dump its (public, simplified) configuration

use Moose::Role;

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

sub dump_config { return {}; }

1;
