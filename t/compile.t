use strict;
use warnings;
use Test::More;

use File::Find::Rule;
use Try::Tiny;

my @files = File::Find::Rule->name('*.pm')->in('lib');
plan tests => scalar @files;

for (@files) {
  s/^lib.//;
  s/.pm$//;
  s{[\\/]}{::}g;

  require_ok($_);
}
