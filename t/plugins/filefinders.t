use strict;
use warnings;
use Test::More 0.88;

use ExtUtils::Manifest 'maniread';
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

my $manifest = maniread($tzil->tempdir->child('build/MANIFEST')->stringify);

my $count = grep { exists $manifest->{$_} } @files;
ok($count == @files, "all files found were in manifest");
ok(keys(%$manifest) == @files, "all files in manifest were on disk");

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

$files = $tzil->find_files(':AllFiles');
is_filelist(
  [ map {; $_->name } @$files ],
  [ @files ],
  ":AllFiles finds all files",
);

$files = $tzil->find_files(':NoFiles');
is_filelist(
  [ map {; $_->name } @$files ],
  [ ],
  ":NoFiles finds no files",
);

done_testing;
