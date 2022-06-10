use strict;
use warnings;
use Test::More 0.88;

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
          exclude_filename => [ 'notme.txt', 'subdir/index.html' ],
        } ],
        [ GatherDir => SelectiveMatch => {
          root   => '../corpus/extra',
          prefix => 'xmatch',
          exclude_match => [ 'notme\.*', '^subdir/index\.html$' ],
        } ],
        [ GatherDir => Symlinks => {
          root   => '../corpus/extra',
          follow_symlinks => 1,
          prefix => 'links',
        } ],
        [ GatherDir => PruneDirectory => {
          root   => '../corpus/extra',
          prefix => 'pruned',
          prune_directory => '^subdir$',
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
    also_copy => { 'corpus/extra' => 'corpus/extra', 'corpus/global' => 'corpus/global' },
  },
);

my $corpus_dir = path($tzil->tempdir)->child('corpus');
if ($^O ne 'MSWin32' && $^O ne 'msys') {
  symlink $corpus_dir->child('extra', 'vader.txt'), $corpus_dir->child('extra', 'vader_link.txt')
    or note "could not create link: $!";

  # link must be to something that is not otherwise being gathered, or we get duplicate errors
  symlink $corpus_dir->child('global'), $corpus_dir->child('extra', 'global_link')
    or note "could not create link: $!";
}

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my @files = map {; $_->name } @{ $tzil->files };

is_filelist(
  [ @files ],
  [ qw(
    bonus/subdir/index.html bonus/vader.txt bonus/notme.txt
    dotty/subdir/index.html dotty/vader.txt dotty/.dotfile dotty/notme.txt
    some/vader.txt
    xmatch/vader.txt
    links/vader.txt links/subdir/index.html links/notme.txt
    pruned/notme.txt pruned/vader.txt
    dist.ini lib/DZT/Sample.pm t/basic.t
    MANIFEST
  ),
    ($^O ne 'MSWin32' && $^O ne 'msys' ? ('links/global_link/config.ini') : ()),
    ($^O ne 'MSWin32' && $^O ne 'msys' ? (map { $_ . '/vader_link.txt' } qw(bonus dotty some xmatch links pruned)) : ()),
  ],
  "GatherDir gathers all files in the source dir",
);

my $manifest = maniread($tzil->tempdir->child('build/MANIFEST')->stringify);

my $count = grep { exists $manifest->{$_} } @files;
ok($count == @files, "all files found were in manifest");
ok(keys(%$manifest) == @files, "all files in manifest were on disk");

diag 'got log messages: ', explain $tzil->log_messages
  if not Test::Builder->new->is_passing;

my @to_remove;

TODO: {
  todo_skip('MSWin32 - skipping symlink test', 1) if $^O eq 'MSWin32' || $^O eq 'msys';

  # tmp/tmp -> tmp/private/tmp
  my $real_tmp = path('tmp', 'private', 'tmp');
  mkpath $real_tmp;
  my $link_tmp = path('tmp', 'tmp');
  symlink 'private/tmp', 'tmp/tmp';

  push @to_remove, [ $real_tmp, $link_tmp ];

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [ GatherDir => { root => 'DZ1' } ],
        ),
      },
      tempdir_root => 'tmp/tmp',
    },
  );

  $tzil->chrome->logger->set_debug(1);
  $tzil->build;

  my @files = map {; $_->name } @{ $tzil->files };

  is_filelist(
    [ @files ],
    [ qw(dist.ini lib/DZ1.pm) ],
    "GatherDir gathers all files in the source dir (canonically corpus/dist/DZ1)",
  );

  diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;
}

for my $pair (@to_remove) {
  $pair->[0]->remove_tree;
  $pair->[1]->remove;
}

done_testing;
