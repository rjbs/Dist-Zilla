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
          { name => undef },
          'GatherDir',
          'TestAutoName',
        ),
      },
    },
  );

  $tzil->build;

  is($tzil->name, 'FooBar', "dist name is set (in DZ obj)");
}

done_testing;
