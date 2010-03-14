use strict;
use warnings;
use Test::More;

use File::Find::Rule;
use Try::Tiny;

my @files = File::Find::Rule->name('*.pm')->in('lib');
plan tests => @files - 1;

for (@files) {
  next if /Tutorial.pm/;
  s/^lib.//;
  s/.pm$//;
  s{[\\/]}{::}g;

  require_ok($_);
}
