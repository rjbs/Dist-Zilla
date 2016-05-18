use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

{
  my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          '@Basic',
          'MetaJSON',
        ),
      },
    },
  );

  $tzil->chrome->logger->set_debug(1);
  is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
  );

  my $build_dir = path($tzil->tempdir)->child('build');
  ok(-e $build_dir->child('META.json'), 'META.json was created successfully');

  diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;
}

done_testing;
