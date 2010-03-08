use strict;
use warnings;
use Test::More;

use Dist::Zilla::App::Tester;

my $result = test_dzil('t/eg/DZ1', [ qw(build) ]);

is($result->exit_code, 0, "exited 0");
# diag($result->build_dir);
# diag $result->output;
# diag explain $result->log_events;

done_testing;
