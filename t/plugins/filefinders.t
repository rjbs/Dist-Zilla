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
        [ ExecDir => ],
        'Manifest',
      ),
    },
    also_copy => { 'corpus/dist/DZT_Inc' => 'corpus/dist/DZT_Inc',
                   'corpus/dist/DZT_Bin' => 'corpus/dist/DZT_Bin'
    },
  },
);

$tzil->build;

my @files = map {; $_->name } @{ $tzil->files };

is_filelist(
  [ @files ],
  [ qw(
    dist.ini lib/DZT/Sample.pm t/basic.t
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

# XXX I don't use sharedir, how do I configure it? --apocal
# disabled for now because DZ::Tester doesn't allow sharedir finder to work...
# Can't locate object method "zilla" via package "Dist::Zilla::Tester::_Builder" at blib/lib/Dist/Zilla/Dist/Builder.pm line 114.
#$files = $tzil->find_files(':ShareFiles');
#is_filelist(
#  [ map {; $_->name } @$files ],
#  [  ],
#  "ShareFiles finds all files",
#);

done_testing;

