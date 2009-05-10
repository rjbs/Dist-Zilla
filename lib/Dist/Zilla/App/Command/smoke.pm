use strict;
use warnings;
package Dist::Zilla::App::Command::smoke;
# ABSTRACT: smoke your dist
use Dist::Zilla::App -command;
require Dist::Zilla::App::Command::test;

sub abstract { 'smoke your dist' }

sub run {
  local $ENV{AUTOMATED_TESTING} = 1;
  
  return Dist::Zilla::App::Command::test::run(@_);
}

1;
