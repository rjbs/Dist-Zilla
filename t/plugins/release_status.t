use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal;

use lib 't/lib';

use Test::DZil;
use JSON::MaybeXS;

# protect from dzil's own release environment
local $ENV{RELEASE_STATUS};
local $ENV{TRIAL};

# TestReleaseProvider sets 'unstable'
subtest "TestReleaseProvider" => sub {
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          'GatherDir',
          'MetaJSON',
          'TestReleaseProvider',
        ),
      },
    },
  );

  $tzil->build;

  is($tzil->release_status, 'unstable', "release status set from provider");
  ok($tzil->is_trial, "is_trial is true");
  like($tzil->archive_filename, qr/-TRIAL/, "-TRIAL in archive filename");

  my $json = $tzil->slurp_file('build/META.json');
  my $meta = JSON::MaybeXS->new(utf8 => 0)->decode($json);
  is( $meta->{release_status}, 'unstable', "release status set in META" );
};

for my $c ( qw/true false/ ) {
    subtest "is_trial in dist.ini $c" => sub {
        my $tzil = Builder->from_config(
            { dist_root => 'corpus/dist/DZT' },
            {
            add_files => {
                'source/dist.ini' => simple_ini(
                { is_trial => $c eq 'true' ? '1' : '0' },
                'GatherDir',
                ),
            },
            },
        );

        $tzil->build;

        my $expect = $c eq 'true' ? 'testing' : 'stable';
        my $is_trial = $expect eq 'testing' ? 1 : 0;

        is($tzil->release_status, $expect, "release status set from is_trial");
        if ( $is_trial ) {
            ok($tzil->is_trial, "is_trial is true");
            like($tzil->archive_filename, qr/-TRIAL/, "-TRIAL in archive filename");
        }
        else {
            ok(! $tzil->is_trial, "is_trial is not true");
            unlike($tzil->archive_filename, qr/-TRIAL/, "-TRIAL not in archive filename");
        }

    };
}

subtest "RELEASE_STATUS" => sub {
  local $ENV{RELEASE_STATUS} = 'stable';
  local $ENV{TRIAL} = 1;
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          'GatherDir',
          'TestReleaseProvider',
        ),
      },
    },
  );

  $tzil->build;

  is($tzil->release_status, 'stable', "release status set from environment");
  ok(! $tzil->is_trial, "is_trial is not true");
  unlike($tzil->archive_filename, qr/-TRIAL/, "-TRIAL not in archive filename");
};

subtest "TRIAL" => sub {
  local $ENV{TRIAL} = 1;
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          'GatherDir',
          'TestReleaseProvider',
        ),
      },
    },
  );

  $tzil->build;

  is($tzil->release_status, 'testing', "release status set from environment");
  ok($tzil->is_trial, "is_trial is true");
  like($tzil->archive_filename, qr/-TRIAL/, "-TRIAL in archive filename");
};

subtest "too many providers" => sub {
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          { is_trial => '1' }, 'GatherDir', 'TestReleaseProvider',
        ),
      },
    },
  );

  like(
    exception { $tzil->build },
    qr/attempted to set release status twice/,
    "setting too many times is fatal",
  );
};

done_testing;
