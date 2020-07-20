use strict;
use warnings;
use Test::More 0.88;
use Test::Deep;

use ExtUtils::Manifest 1.66; # or maniread can't cope with quoting properly

use Test::DZil;

my $tzil = Builder->from_config(
  { dist_root => 'corpus/dist/DZT' },
  {
    add_files => {
      q{source/file with spaces.txt}        => "foo\n",
      q{source/'file-with-ticks.txt'}       => "baz\n",
      'source/dist.ini' => simple_ini(
        'GatherDir',
        'Manifest',
      ),
      $^O =~ /^(MSWin32|cygwin|msys)$/ ? () : (
        q{source/file\\with some\\whacks.txt} => "bar\n",
        q{source/file'with'quotes\\or\\backslash.txt} => "quux\n",
        q{source/dir\\with some\\/whacks.txt} => "mar\n",
      ),
    },
  },
);

$tzil->build;

my $manihash = ExtUtils::Manifest::maniread($tzil->built_in->child('MANIFEST'));

cmp_deeply(
  [ keys %$manihash ],
  bag(
    'MANIFEST',
    q{file with spaces.txt},
    q{'file-with-ticks.txt'},
    'dist.ini',
    'lib/DZT/Sample.pm',
    't/basic.t',
    $^O =~ /^(MSWin32|cygwin|msys)$/ ? () : (
      q{file\\with some\\whacks.txt},
      q{file'with'quotes\\or\\backslash.txt},
      q{dir\\with some\\/whacks.txt},
    ),
  ),
  'manifest quotes files with spaces'
);

my @manilines = grep { ! /^#/ } split /\n/, $tzil->slurp_file('build/MANIFEST');
chomp @manilines;

cmp_deeply(
  \@manilines,
  bag(
    'MANIFEST',
    q{'file with spaces.txt'},
    q{'\\'file-with-ticks.txt\\''},
    'dist.ini',
    'lib/DZT/Sample.pm',
    't/basic.t',
    $^O =~ /^(MSWin32|cygwin|msys)$/ ? () : (
      q{'file\\\\with some\\\\whacks.txt'},
      q{'file\\'with\\'quotes\\\\or\\\\backslash.txt'},
      q{'dir\\\\with some\\\\/whacks.txt'},
    ),
  ),
  'manifest quotes files with spaces'
);

done_testing;
