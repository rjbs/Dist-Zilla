use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Test::DZil;
use YAML::Tiny;

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {
            license => undef,
            copyright_year => 2012,
          },
          'GatherDir',
          'TestAutoLicense',
        ),
      },
    },
  );

  $tzil->build;

  is($tzil->license->name, '"No License" License', "dist license is set by plugin");
  is($tzil->license->year, 2012, "copyright_year used instead of default year");
}

done_testing;
