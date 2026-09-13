use v5.22.0;
use warnings;
use experimental qw(signatures);
use Test::More 0.88;

use Test::DZil;

my $this_year = (localtime)[5] + 1900;

sub year_is ($config, $expected, $desc, @sections) {
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini($config, "GatherDir", @sections),
      },
    },
  );

  is($tzil->license->year, $expected, $desc);
}

year_is(
  { copyright_year => undef },
  $this_year,
  "with no copyright_year, the year is this year",
);

year_is(
  { copyright_year => 2012 },
  2012,
  "a literal year is passed through unchanged",
);

year_is(
  { copyright_year => '2008 - 2012' },
  '2008 - 2012',
  "a literal range is passed through unchanged",
);

year_is(
  { copyright_year => '$this_year' },
  $this_year,
  '$this_year alone is replaced with this year',
);

year_is(
  { copyright_year => '2008 - $this_year' },
  "2008 - $this_year",
  '$this_year at the end of a range is replaced with this year',
);

year_is(
  { copyright_year => '$this_yearly' },
  '$this_yearly',
  '$this_year requires a word boundary, so $this_yearly is left alone',
);

year_is(
  { copyright_year => undef },
  "2008 - $this_year",
  '$this_year is replaced when the year comes from the %Rights stash',
  [ "%Rights" => {
    license_class    => "Perl_5",
    copyright_holder => "E. Xavier Ample",
    copyright_year   => q{2008 - $this_year},
  } ],
);

done_testing;
