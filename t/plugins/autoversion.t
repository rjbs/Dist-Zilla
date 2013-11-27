use strict;
use warnings;
use Test::More 0.88;

use Test::DZil;
use YAML::Tiny;

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          { version => undef },
          'GatherDir',
          [ AutoVersion => { major => 6, format => '{{$major}}.{{$^T}}' } ],
        ),
      },
    },
  );

  $tzil->build;

  my $want_version = "6." . $^T;

  is($tzil->version, $want_version, "dist version is set (in DZ obj)");
}

done_testing;
