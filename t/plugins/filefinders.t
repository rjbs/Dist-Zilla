use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Test::DZil;

my $tzil = Builder->from_config(
  { dist_root => 'corpus/dist/DZT' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        [ GatherDir => ],
        [ GatherDir => MyINC => {
          root   => '../corpus/dist/DZT_Inc',
          prefix => 'inc',
        } ],
        [ GatherDir => MyBIN => {
          root   => '../corpus/dist/DZT_Bin',
          prefix => 'bin',
        } ],
        [ GatherDir => MySHARE => {
          root   => '../corpus/dist/DZT_Share',
          prefix => 'share',
        } ],
        [ ExecDir => ],
        [ ShareDir => ],
        'Manifest',
      ),
    },
    also_copy => { 'corpus/dist/DZT_Inc' => 'corpus/dist/DZT_Inc',
                   'corpus/dist/DZT_Bin' => 'corpus/dist/DZT_Bin',
                   'corpus/dist/DZT_Share' => 'corpus/dist/DZT_Share'
    },
  },
);

$tzil->build;

my @files = map {; $_->name } @{ $tzil->files };

is_filelist(
  [ @files ],
  [ qw(
    dist.ini lib/DZT/Sample.pm
    share/my_data.dat
    t/basic.t
    MANIFEST
    inc/Foo.pm inc/Foo/Bar.pm
    bin/test.pl
  ) ],
  "GatherDir gathers all files in the source dir",
);

my $manifest = $tzil->slurp_file('build/MANIFEST');
my %in_manifest = map {; chomp; $_ => 1 } grep {length} split /\n/, $manifest;

my $count = grep { $in_manifest{$_} } @files;
ok($count == @files, "all files found were in manifest");
ok(keys(%in_manifest) == @files, "all files in manifest were on disk");

# Test our finders
my $files = $tzil->find_files(':InstallModules');
is_filelist(
  [ map {; $_->name } @$files ],
  [ qw(
    lib/DZT/Sample.pm
  ) ],
  "InstallModules finds all modules",
);

$files = $tzil->find_files(':IncModules');
is_filelist(
  [ map {; $_->name } @$files ],
  [ qw(
    inc/Foo.pm inc/Foo/Bar.pm
  ) ],
  "IncModules finds all modules",
);

$files = $tzil->find_files(':TestFiles');
is_filelist(
  [ map {; $_->name } @$files ],
  [ qw(
    t/basic.t
  ) ],
  "TestFiles finds all files",
);

$files = $tzil->find_files(':ExecFiles');
is_filelist(
  [ map {; $_->name } @$files ],
  [ qw(
    bin/test.pl
  ) ],
  "ExecFiles finds all files",
);

$files = $tzil->find_files(':ShareFiles');
is_filelist(
  [ map {; $_->name } @$files ],
  [ qw(
    share/my_data.dat
  ) ],
  "ShareFiles finds all files",
);

$files = $tzil->find_files(':All');
is_filelist(
  [ map {; $_->name } @$files ],
  [ @files ],
  "All finds all files",
);

$files = $tzil->find_files(':None');
is_filelist(
  [ map {; $_->name } @$files ],
  [ ],
  "None finds no files",
);

done_testing;
