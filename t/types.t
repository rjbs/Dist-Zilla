use strict;
use warnings;

use Test::More 0.88;

use Dist::Zilla::Types qw(VersionStr);

ok(is_VersionStr($_), "$_ isa VersionStr") foreach qw(1.23 1.23000 1.004_002 v1.23 v1.23.45);

ok(!is_VersionStr($_), "$_ is not a VersionStr") foreach qw(v1.23_01 v1.23.45_01 1.23.45_01);

done_testing;
