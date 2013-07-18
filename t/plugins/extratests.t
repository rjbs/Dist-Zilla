use strict;
use warnings;
use Test::More 0.88;

use autodie;
use Test::DZil;
use Test::Deep;

my $generic_test = <<'END_TEST';
#!perl

use strict;
use warnings;

use Test::More 0.88;

use Foo::%s 392;

ok(0, "stop building me!");

done_testing;
END_TEST

my @xt_types = qw(smoke author release);

my $tzil = Builder->from_config(
  { dist_root => 'corpus/dist/DZT' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(qw<GatherDir ExtraTests AutoPrereqs>),
      (map {; "source/xt/$_/huffer.t" => sprintf($generic_test, $_) }
           @xt_types, qw(blort))
    },
  },
);

$tzil->build;

my @files = map {; $_->name } @{ $tzil->files };

cmp_deeply(
  \@files,
  bag(qw(
    dist.ini lib/DZT/Sample.pm t/basic.t
    t/smoke-huffer.t
    t/author-huffer.t
    t/release-huffer.t
    xt/blort/huffer.t
  )),
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

cmp_deeply(
  $tzil->distmeta,
  superhashof({
    prereqs => {
      runtime => {
        requires => {
          strict => 0,
          warnings => 0,
        },
      },
      test => {
        requires => {
          'Test::More' => '0.88',
          'Foo::smoke' => '392',
          # Foo::author and Foo::release are
          # not here because they are not required by the end user
          # (See RT#76305)
        },
      },
      develop => {
        requires => {
          # remaining xt/ files were moved aside and not scanned
          'Foo::blort' => '392',
          'Test::More' => '0.88',
        },
      },
    },
  }),
  'dependencies ok',
) or diag $tzil->distmeta;

done_testing;
