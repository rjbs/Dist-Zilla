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
        [ GatherDir => {
          root => '../corpus/spacey',
        } ],
        'Manifest',
      ),
    },
    also_copy => { 'corpus/spacey' => 'corpus/spacey' },
  },
);

$tzil->build;

my $manifest = $tzil->slurp_file('build/MANIFEST');
my @in_manifest = map {; chomp; $_ } grep {length} split /\n/, $manifest;

is_filelist(
  \@in_manifest,
  ['MANIFEST', q{'File With Spaces.txt'}],
  'Manifest quotes files with spaces'
);

done_testing;
