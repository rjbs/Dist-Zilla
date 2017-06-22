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
        path(qw(source dist.ini)) => simple_ini(
          [ 'GatherFile' => {
              filename => 'lib/DZT/Sample.pm',
            }],
        ),
        path(qw(source lib DZT Sample.pm)) => "package DZT::Sample;\n1",
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
  ok(-e $build_dir->child(qw(lib DZT Sample.pm)), 'file was gathered correctly');

  diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
      add_files => {
        path(qw(source dist.ini)) => simple_ini(
          [ 'GatherFile' => {
              filename => 'lib/DZT/Sample.pm',
            }],
        ),
        # no source/lib/DZT/Sample.pm
      },
    },
  );

  $tzil->chrome->logger->set_debug(1);
  like(
    exception { $tzil->build },
    qr{lib/DZT/Sample.pm does not exist!},
    'missing file is detected',
  );

  diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
      add_files => {
        path(qw(source dist.ini)) => simple_ini(
          [ 'GatherFile' => {
              filename => 'subdir/index.html',
              root => 'corpus/extra',
            }],
        ),
      },
      also_copy => { 'corpus/extra' => 'source/corpus/extra' },
    },
  );

  $tzil->chrome->logger->set_debug(1);
  is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
  );

  my $build_dir = path($tzil->tempdir)->child('build');
  ok(-e $build_dir->child(qw(subdir index.html)), 'file was gathered correctly from a different root');

  diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
      add_files => {
        path(qw(source dist.ini)) => simple_ini(
          [ 'GatherFile' => {
              filename => 'lib/DZT/Sample.pm',
              prefix => 'stuff',
            }],
        ),
        path(qw(source lib DZT Sample.pm)) => "package DZT::Sample;\n1",
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
  ok(-e $build_dir->child(qw(stuff lib DZT Sample.pm)), 'file was gathered correctly into the prefix dir');

  diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;
}

done_testing;
