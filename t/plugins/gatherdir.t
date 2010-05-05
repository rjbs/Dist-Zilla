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
        [ GatherDir => ],
        [ GatherDir => BonusFiles => {
          root   => '../corpus/extra',
          prefix => 'bonus',
        } ],
        [ GatherDir => DottyFiles => {
          root   => '../corpus/extra',
          prefix => 'dotty',
          include_dotfiles => 1,
        } ],
        'Manifest',
      ),
      'source/.profile' => "Bogus dotfile.\n",
      'corpus/extra/.dotfile' => "Bogus dotfile.\n",
    },
    also_copy => { 'corpus/extra' => 'corpus/extra' },
  },
);

$tzil->build;

my @files = map {; $_->name } @{ $tzil->files };

is_filelist(
  [ @files ],
  [ qw(
    bonus/subdir/index.html bonus/vader.txt
    dotty/subdir/index.html dotty/vader.txt dotty/.dotfile
    dist.ini lib/DZT/Sample.pm t/basic.t
    MANIFEST
  ) ],
  "GatherDir gathers all files in the source dir",
);

my $manifest = $tzil->slurp_file('build/MANIFEST');
my %in_manifest = map {; chomp; $_ => 1 } grep {length} split /\n/, $manifest;

my $count = grep { $in_manifest{$_} } @files;
ok($count == @files, "all files found were in manifest");
ok(keys(%in_manifest) == @files, "all files in manifest were on disk");

done_testing;

