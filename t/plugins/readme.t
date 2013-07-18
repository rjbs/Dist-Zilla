use strict;
use warnings;
use Test::More 0.88;
use utf8;

use autodie;
use Test::DZil;

my $tzil = Builder->from_config(
  { dist_root => 'corpus/dist/DZT' },
  {
    add_files => {
      'source/dist.ini' => simple_ini('Readme'),
    },
  },
);

$tzil->build;

my $contents = $tzil->slurp_file('build/README');

like(
  $contents,
  qr{This software is copyright .c. [0-9]+ by E\. Xavier Ample}i,
  "copyright appears in README file",
);

like(
  $contents,
  qr{same terms as (the )?perl.*itself}i,
  "'same terms as perl'-ish text appears in README",
);

my $name = $tzil->name;
like(
  $contents,
  qr{\Q$name\E},
  "dist name appears in README",
);

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZ-NonAscii' },
  );

  $tzil->build;

  my $contents = $tzil->slurp_file('build/README');

  like(
    $contents,
    qr{ภูมิพลอดุลยเดช},
    "HRH unmangled in README",
  );
}

done_testing;

