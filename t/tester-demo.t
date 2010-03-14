use strict;
use warnings;
use Test::More 0.88;

use Dist::Zilla::App::Tester;
use Dist::Zilla::Tester;

## SIMPLE TEST WITH DZIL::APP TESTER

my $result = test_dzil('t/eg/DZ1', [ qw(build) ]);

is($result->exit_code, 0, "dzil would have exited 0");

ok(
  (grep { $_ eq '[DZ] writing archive to DZ1-0.001.tar.gz' }
    @{ $result->log_messages }),
  "we logged the archive-creation",
);

## SIMPLE TEST WITH DZIL TESTER

my $tester = Dist::Zilla::Tester->from_config({ dist_root => 't/eg/DZ1' });

$tester->build_in;

ok(
  (grep { $_->{message} =~ m<^\[DZ\]\s> } @{ $tester->logger->events }),
  "we have at least some expected log content",
);

use YAML::Tiny;
my $yaml = YAML::Tiny->read($tester->built_in->file('META.yml'));
my $meta = $yaml->[0];

like($meta->{generated_by}, qr{Dist::Zilla}, "powered by... ROBOT DINOSAUR");

done_testing;
