use strict;
use warnings;
use Test::More 'no_plan';

use Dist::Zilla;
my $dzil = Dist::Zilla->from_config({
  dist_root => 'eg/DZ1',
});


