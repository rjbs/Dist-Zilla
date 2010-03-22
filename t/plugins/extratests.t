use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use autodie;
use Test::DZil;

my $generic_test = <<'END_TEST';
#!perl

use strict;
use warnings;

use Test::More 0.88;

ok(0, "stop building me!");

done_testing;
END_TEST

my @xt_types = qw(smoke author release);

my $tzil = Dist::Zilla::Tester->from_config(
  { dist_root => 'corpus/DZT' },
  {
    add_files => {
      'source/dist.ini' => simple_ini('GatherDir', 'ExtraTests'),
      (map {; "source/xt/$_/huffer.t" => $generic_test }
           @xt_types, qw(blort))
    },
  },
);

$tzil->build;

my @files = map {; $_->name } @{ $tzil->files };

is_deeply(
  [ sort @files ],
  [ sort qw(
    dist.ini lib/DZT/Sample.pm t/basic.t
    t/smoke-huffer.t
    t/author-huffer.t
    t/release-huffer.t
    xt/blort/huffer.t
  ) ],
  "filenames rewritten by ExtraTests",
);

for my $type (@xt_types) {
  my $test_program = $tzil->slurp_file("build/t/$type-huffer.t");
  my $env = uc sprintf "%s_TESTING", $type eq 'smoke' ? 'automated' : $type;

  like(
    $test_program,
    qr/\$ENV\{$env\}/,
    "we mention $env in the rewritten $type test",
  );
}

done_testing;
