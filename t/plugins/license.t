use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use autodie;
use Test::DZil;

my $tzil = Dist::Zilla::Tester->from_config(
  { dist_root => 'corpus/DZT' },
  {
    add_files => {
      'source/dist.ini' => simple_ini('License'),
    },
  },
);

$tzil->build;

my $contents = $tzil->slurp_file('build/LICENSE');

like(
  $contents,
  qr{This software is copyright .c. [0-9]+ by E\. Xavier Ample}i,
  "copyright appears in LICENSE file",
);

like(
  $contents,
  qr{same terms as (the )?perl.*itself}i,
  "'same terms as perl'-ish text appears in LICENSE",
);

done_testing;

