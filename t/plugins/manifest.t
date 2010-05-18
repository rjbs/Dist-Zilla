use strict;
use warnings;
use Test::More 0.88;

use ExtUtils::Manifest;

use lib 't/lib';

use Test::DZil;

my $tzil = Dist::Zilla::Tester->from_config(
  { dist_root => 'corpus/DZT' },
  {
    add_files => {
      q{source/file with spaces.txt}        => "foo\n",
      q{source/file\\with some\\whacks.txt} => "bar\n",
      # q{source/'file-with-ticks.txt'}       => "baz\n",
      q{source/file'with'quotes\\or\\backslash.txt} => "quux\n",
      'source/dist.ini' => simple_ini(
        'GatherDir',
        'Manifest',
      ),
    },
  },
);

$tzil->build;

my $manihash = ExtUtils::Manifest::maniread($tzil->built_in->file('MANIFEST'));

is_deeply(
  [ sort keys %$manihash ],
  [ sort(
    'MANIFEST',
    q{file with spaces.txt},
    q{file\\with some\\whacks.txt},
    q{file'with'quotes\\or\\backslash.txt},
    # q{'file-with-ticks.txt'},
    'dist.ini',
    'lib/DZT/Sample.pm',
    't/basic.t',
  ) ],
  'manifest quotes files with spaces'
);

my @manilines = split /\n/, $tzil->slurp_file('build/MANIFEST');
chomp @manilines;

is_deeply(
  [ sort @manilines ],
  [ sort(
    'MANIFEST',
    q{'file with spaces.txt'},
    q{'file\\\\with some\\\\whacks.txt'},
    # q{'\\'file-with-ticks.txt\\''},
    q{'file\\'with\\'quotes\\\\or\\\\backslash.txt'},
    'dist.ini',
    'lib/DZT/Sample.pm',
    't/basic.t',
  ) ],
  'manifest quotes files with spaces'
);

done_testing;
