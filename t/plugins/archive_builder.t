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

my $fooball = $tzil->build_archive;

note "fooball = $fooball";
note "is_trial = @{[ $tzil->is_trial ]}";

my @payload = JSON::MaybeXS->new->decode( $fooball->slurp_raw )->@*;

is $payload[0], 'DZT-Sample-0.001-TRIAL';
ok -d $payload[1];
is $payload[2], 'DZT-Sample-0.001';

unlink $fooball;

done_testing;
