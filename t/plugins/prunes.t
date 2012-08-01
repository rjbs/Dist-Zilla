use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Test::DZil;

for my $skip_skip (0..3) {
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [ GatherDir => ],
          [ GatherDir => BonusFiles => {
            root   => '../corpus/extra',
            prefix => 'bonus',
          } ],
          ($skip_skip > 1 ? 'ManifestSkip' : ()),
        ),
        'source/MANIFEST.SKIP' => join('', map {; "$_\n" } (
          'dist.ini',
          '.*\.txt',
          ($skip_skip & 1 ? 'MANIFEST.SKIP' : ()),
        )),
      },
      also_copy => { 'corpus/extra' => 'corpus/extra' },
    },
  );

  $tzil->build;

  my @files = map {; $_->name } @{ $tzil->files };

  is_filelist(
    $tzil->files,
    [ qw(bonus/subdir/index.html lib/DZT/Sample.pm t/basic.t),
      ($skip_skip >= 2 ? () : ('dist.ini', 'bonus/vader.txt')),
      ($skip_skip == 3 ? () : 'MANIFEST.SKIP'),
    ],
    "ManifestSkip prunes files from MANIFEST.SKIP ($skip_skip)",
  );
}

# Test ManifestSkip with InlineFiles-generated files RT#76036
for my $skip_skip (0..1) {
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [ GatherDir => ],
          [ GatherDir => BonusFiles => {
            root   => '../corpus/extra',
            prefix => 'bonus',
          } ],
          'JustForManifestSkipTests',
          ($skip_skip & 1 ? [ ManifestSkip => { skipfile => 'FOO.SKIP' } ] : ()),
        ),
      },
      also_copy => { 'corpus/extra' => 'corpus/extra' },
    },
  );

  $tzil->build;

  my @files = map {; $_->name } @{ $tzil->files };

  is_filelist(
    $tzil->files,
    [ qw(bonus/subdir/index.html lib/DZT/Sample.pm t/basic.t),
      ($skip_skip & 1 ? () : (qw(foo.txt dist.ini bonus/vader.txt FOO.SKIP))),
    ],
    "ManifestSkip prunes files from generated FOO.SKIP ($skip_skip)",
  );
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/Build'    => "This file is cruft.\n",
        'source/dist.ini' => simple_ini('GatherDir'),
      },
    },
  );

  $tzil->build;

  my @files = map {; $_->name } @{ $tzil->files };

  is_filelist(
    [ @files ],
    [ qw(dist.ini lib/DZT/Sample.pm t/basic.t Build) ],
    "./Build is included by default...",
  );
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/Build'    => "This file is cruft.\n",
        'source/dist.ini' => simple_ini('GatherDir', 'PruneCruft'),
      },
    },
  );

  $tzil->build;

  my @files = map {; $_->name } @{ $tzil->files };

  is_filelist(
    [ @files ],
    [ qw(dist.ini lib/DZT/Sample.pm t/basic.t) ],
    "...but /Build is pruned by PruneCruft",
  );
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/Build'    => "This file is cruft.\n",
        'source/dist.ini' => simple_ini(
            'GatherDir',
            [ 'PruneCruft' => { except => 'Build' } ],
        ),
      },
    },
  );

  $tzil->build;

  my @files = map {; $_->name } @{ $tzil->files };

  is_filelist(
    [ @files ],
    [ qw(dist.ini lib/DZT/Sample.pm t/basic.t Build) ],
    "...but /Build isn't  pruned by PruneCruft if we exclude it",
  );
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/_Inline/foo.c'  => "This file is cruft.\n",
        'source/dist.ini' => simple_ini('GatherDir', 'PruneCruft'),
      },
    },
  );

  $tzil->build;

  my @files = map {; $_->name } @{ $tzil->files };

  is_filelist(
    [ @files ],
    [ qw(dist.ini lib/DZT/Sample.pm t/basic.t) ],
    "./_Inline/* is excluded by default...",
  );
}

for my $arg (qw(filename filenames)) {
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          'GatherDir',
          [ PruneFiles => { $arg => 'dist.ini' } ],
        ),
      },
    },
  );

  $tzil->build;

  my @files = map {; $_->name } @{ $tzil->files };

  is_filelist(
    [ @files ],
    [ qw(lib/DZT/Sample.pm t/basic.t) ],
    "we can prune a specific file by request (arg $arg)",
  );
}

done_testing;

