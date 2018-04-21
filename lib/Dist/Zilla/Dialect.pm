package Dist::Zilla::Dialect;

use v5.20.0;
use warnings;
use experimental ();

sub import {
  feature->import(':5.20');
  experimental->import(qw(lexical_subs postderef signatures));
}

1;
