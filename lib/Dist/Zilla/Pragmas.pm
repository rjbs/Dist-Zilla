package Dist::Zilla::Pragmas;
# ABSTRACT: the pragmas (boilerplate!) to enable in each Dist::Zilla module

use v5.20.0;
use warnings;
use utf8;

use experimental qw(signatures);

sub import {
  warnings->import;
  utf8->import;

  feature->unimport(':all');
  feature->import(':5.20');
  feature->unimport('switch');

#begin babble
  experimental->import(qw(
    lexical_subs
    postderef
    postderef_qq
    signatures
  ));
#end babble

  feature->unimport('multidimensional') if $] >= 5.034;
}

1;
