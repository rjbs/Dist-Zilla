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
        [ GatherDir => BonusFiles => {
          root   => '../corpus/extra',
          prefix => 'bonus',
        } ],
        [ GatherDir => DottyFiles => {
          root   => '../corpus/extra',
          prefix => 'dotty',
          include_dotfiles => 1,
        } ],
        [ GatherDir => Selective => {
          root   => '../corpus/extra',
          prefix => 'some',
          exclude_filename => 'notme.txt',
        } ],
        [ GatherDir => WholeFilename => {
          root   => '../corpus/extra',
          prefix => 'anchor',
          exclude_filename => 'notme',
        } ],
        [ GatherDir => SelectiveMatch => {
          root   => '../corpus/extra',
          prefix => 'xmatch',
          exclude_match => 'notme\..*',
        } ],
        'Manifest',
      ),
      'source/.profile' => "Bogus dotfile.\n",
      'corpus/extra/.dotfile' => "Bogus dotfile.\n",
      'corpus/extra/notme.txt' => "A file to exclude.\n",
      'corpus/extra/notme' => "A filename to test that filename matches the whole filename.\n",
    },
    also_copy => { 'corpus/extra' => 'corpus/extra' },
  },
);

$tzil->build;

my @files = map {; $_->name } @{ $tzil->files };

is_filelist(
  [ @files ],
  [ qw(
    bonus/subdir/index.html     bonus/vader.txt     bonus/notme.txt bonus/notme
    dotty/subdir/index.html     dotty/vader.txt     dotty/notme.txt dotty/notme     dotty/.dotfile
    some/subdir/index.html      some/vader.txt                      some/notme
    xmatch/subdir/index.html    xmatch/vader.txt                    xmatch/notme
    anchor/subdir/index.html    anchor/vader.txt    anchor/notme.txt
    dist.ini lib/DZT/Sample.pm t/basic.t
    MANIFEST
  ) ],
  "GatherDir gathers all files in the source dir",
) or diag explain \@files;

my $manifest = $tzil->slurp_file('build/MANIFEST');
my %in_manifest = map {; chomp; $_ => 1 } grep {length} split /\n/, $manifest;

my $count = grep { $in_manifest{$_} } @files;
ok($count == @files, "all files found were in manifest");
ok(keys(%in_manifest) == @files, "all files in manifest were on disk");

done_testing;

