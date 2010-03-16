use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Test::DZil;

my $tzil = Dist::Zilla::Tester->from_config(
  { dist_root => 'corpus/DZT' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        [ AllFiles => ],
        [ AllFiles => ExtraFiles => {
          root   => '../corpus/extra',
          prefix => 'bonus',
        } ],
      ),
      'source/.profile' => "Bogus dotfile.\n",
      'corpus/extra/.dotfile' => "Bogus dotfile.\n",
    },
    also_copy => { 'corpus/extra' => 'corpus/extra' },
  },
);

$tzil->build;

is_deeply(
  [ sort map {; $_->name } @{ $tzil->files } ],
  [ sort qw(
    bonus/subdir/index.html bonus/vader.txt
    dist.ini lib/DZT/Simple.pm t/basic.t
  ) ],
  "AllFiles gathers all files in the source dir",
);

done_testing;

