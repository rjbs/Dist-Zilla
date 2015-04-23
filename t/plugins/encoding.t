use strict;
use warnings;
use Test::More 0.88;
use utf8;

use autodie;
use Test::DZil;

my $ini = <<'END_INI';
license = Perl_5
author = E. Xavier Ample <example@example.org>
abstract = Sample DZ Dist
name = DZT-Sample
copyright_holder = E. Xavier Ample
version = 0.001

[GatherDir]

[Encoding / general]
encoding=utf8
match=^
ignore=^t/

[Encoding / subset]
encoding=bytes
match=^t/

END_INI


my $tzil = Builder->from_config(
  { dist_root => 'corpus/dist/DZT' },
  {
    add_files => {
      'source/dist.ini' => $ini
    },
  },
);

$tzil->build;


pass;

done_testing;

