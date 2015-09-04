use strict;
use warnings;
use Test::More 0.88;
use Test::Deep;

use Test::DZil;

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [ GatherDir => ],
          [ PodSyntaxTests => ],
        ),
      },
    },
  );

  $tzil->build;

  cmp_deeply(
    $tzil->distmeta,
    superhashof(
      {
        prereqs =>
        {
           develop => { requires => { 'Test::Pod' => '1.41' } },
        },
      }
    ),
    'PodSyntaxTests develop prereqs'
  );

  like(
    $tzil->slurp_file('build/xt/author/pod-syntax.t'),
    qr/\Quse Test::Pod 1.41/,
    'xt/release/pod-syntax.t content'
  );
}

done_testing;
