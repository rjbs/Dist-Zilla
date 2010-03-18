use strict;
use warnings;

use Test::More 0.88;
use DZT::Sample;

is_deeply(
  DZT::Sample->return_arrayref_of_values_passed(1, [ 2 ], { 3 => 4 }),
  [ 1, [ 2 ], { 3 => 4 } ],
  "we do what we say on the tin",
);

done_testing;
