use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use ExtUtils::Manifest 'maniread';
use Test::DZil;
use Path::Tiny;

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
        [ GatherDir => SelectiveMatch => {
          root   => '../corpus/extra',
          prefix => 'xmatch',
          exclude_match => 'notme\.*',
        } ],
        [ GatherDir => Symlinks => {
          root   => '../corpus/extra',
          follow_symlinks => 1,
          prefix => 'links',
        } ],
        'Manifest',
        'MetaConfig',
      ),
      'source/.profile' => "Bogus dotfile.\n",
      'corpus/extra/.dotfile' => "Bogus dotfile.\n",
      'corpus/extra/notme.txt' => "A file to exclude.\n",
      'source/.dotdir/extra/notme.txt' => "Another file to exclude.\n",
      'source/extra/.dotdir/notme.txt' => "Another file to exclude.\n",
    },
    also_copy => { 'corpus/extra' => 'corpus/extra' },
  },
);

my $corpus_dir = path($tzil->tempdir)->child('corpus');
symlink $corpus_dir->child('extra', 'vader.txt'), $corpus_dir->child('extra', 'vader_link.txt')
    or note "could not create link: $!"
  if $^O ne 'MSWin32';

$tzil->build;

my @files = map {; $_->name } @{ $tzil->files };

is_filelist(
  [ @files ],
  [ qw(
    bonus/subdir/index.html bonus/vader.txt bonus/notme.txt
    dotty/subdir/index.html dotty/vader.txt dotty/.dotfile dotty/notme.txt
    some/subdir/index.html some/vader.txt
    xmatch/subdir/index.html xmatch/vader.txt
    links/vader.txt links/subdir/index.html links/notme.txt
    dist.ini lib/DZT/Sample.pm t/basic.t
    MANIFEST
  ),
    ($^O ne 'MSWin32' ? (map { $_ . '/vader_link.txt' } qw(bonus dotty some xmatch links)) : ()),
  ],
  "GatherDir gathers all files in the source dir",
);

my $manifest = maniread($tzil->tempdir->file('build/MANIFEST')->stringify);

my $count = grep { exists $manifest->{$_} } @files;
ok($count == @files, "all files found were in manifest");
ok(keys(%$manifest) == @files, "all files in manifest were on disk");

done_testing;

