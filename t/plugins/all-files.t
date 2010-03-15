use strict;
use warnings;
use Test::More 0.88;

use Dist::Zilla::Tester;

my $dist_ini = <<'END_INI';
name     = DZT-Sample
abstract = Sample DZ Dist
version  = 0.001
author   = E. Xavier Ample <example@example.org>
license  = Perl_5
copyright_holder = E. Xavier Ample

[AllFiles]

[AllFiles / ExtraFiles]
root = ../corpus/extra
prefix = bonus
END_INI

my $tzil = Dist::Zilla::Tester->from_config(
  { dist_root => 'corpus/DZT' },
  {
    add_files => {
      'source/dist.ini' => $dist_ini,
      'source/.profile' => "Bogus dotfile.\n",
      'corpus/extra/.dotfile' => "Bogus dotfile.\n",
    },
    callbacks => [ ],
    also_copy => { 'corpus/extra' => 'corpus/extra' },
  },
);

$tzil->build;

is_deeply(
  [ sort map {; $_->name } @{ $tzil->files } ],
  [ sort qw(
    bonus/subdir/index.html bonus/vader.txt
    dist.ini lib/DZT/Simple.pm t/basic.t
  ) ],
  "AllFiles gathers all files in the source dir",
);

done_testing;

