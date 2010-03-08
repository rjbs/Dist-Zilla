use strict;
use warnings;
use Test::More;

use Dist::Zilla::App::Tester;
use Dist::Zilla::Tester;

my $result = test_dzil('t/eg/DZ1', [ qw(build) ]);

is($result->exit_code, 0, "exited 0");
# diag($result->build_dir);
# diag $result->output;
# diag explain $result->log_events;

my $tester = Dist::Zilla::Tester->from_config({ dist_root => 't/eg/DZ1' });

$tester->build_in;

use YAML::Tiny;
my $yaml = YAML::Tiny->read($tester->built_in->file('META.yml'));
my $meta = $yaml->[0];

like($meta->{generated_by}, qr{Dist::Zilla}, "powered by... ROBOT DINOSAUR");

done_testing;
