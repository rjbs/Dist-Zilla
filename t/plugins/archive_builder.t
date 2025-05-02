use strict;
use warnings;
use Test::More 0.88;
use experimental qw( postderef );

use lib 't/lib';

use Test::DZil;
use JSON::MaybeXS;

my $tzil = Builder->from_config(
  { dist_root => 'corpus/dist/DZT' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        'GatherDir',
        'TestArchiveBuilder',
        'TestReleaseProvider',
      ),
    },
  },
);

$tzil->trial_num(42);
my $fooball = $tzil->build_archive;

note "fooball = $fooball";
note "is_trial = @{[ $tzil->is_trial ]}";
note "trial_num = @{[ $tzil->trial_num ]}";

my @payload = JSON::MaybeXS->new->decode( $fooball->slurp_raw )->@*;

is $payload[0], 'DZT-Sample-0.001-TRIAL42';
ok -d $payload[1];
is $payload[2], 'DZT-Sample-0.001';

unlink $fooball;

done_testing;
