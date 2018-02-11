use strict;
use warnings;
use Test::More 0.88;

use Test::DZil;
use YAML::Tiny;

delete $ENV{V};

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          { version => undef },
          'GatherDir',
          [ AutoVersion => { major => 6, format => '{{$major}}.{{$^T}}' } ],
        ),
      },
    },
  );

  $tzil->build;

  my $want_version = "6." . $^T;

  is($tzil->version, $want_version, "dist version is set (in DZ obj)");
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          { version => undef },
          'GatherDir',
          [ AutoVersion => {
            major => 7,
            format => q<{{$major}}.{{ cldr('y') }}> } ],
        ),
      },
    },
  );

  $tzil->build;

  like($tzil->version, qr/^7\.20[1-9][0-9]$/, "dist version is set using CLDR");
}

{
  local $ENV{V} = '1.23';
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          { version => undef },
          'GatherDir',
          [ AutoVersion => { major => 6, format => '{{$major}}.{{$^T}}' } ],
        ),
      },
    },
  );

  $tzil->build;

  is($tzil->version, '1.23', "dist version is set from \$V override");
}
done_testing;
