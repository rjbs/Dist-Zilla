package Dist::Zilla::ConfigRole::Findable;
use Moose::Role;
# ABSTRACT: a config class that Dist::Zilla::Config::Finder can find

requires 'can_be_found';

no Moose::Role;
1;
