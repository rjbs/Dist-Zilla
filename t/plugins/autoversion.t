use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Test::DZil;
use YAML::Tiny;

{
  my $tzil = Dist::Zilla::Tester->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          { version => undef },
          'AllFiles',
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
