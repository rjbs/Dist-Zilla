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
          { abstract => undef },
          'GatherDir',
          'TestAutoAbstract',
        ),
      },
    },
  );

  $tzil->build;

  is($tzil->abstract, 'Blah blah blah', "dist abstract is set (in DZ obj)");
}

done_testing;
