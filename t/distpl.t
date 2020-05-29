use strict;
use warnings;
use Test::More 0.88;

use Test::DZil;

my $tzil = Builder->from_config(
  { dist_root => 'corpus/dist/DZ2' },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;
pass();
done_testing;
