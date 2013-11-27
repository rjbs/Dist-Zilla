use strict;
use warnings;
use Test::More 0.88;
use Test::Deep;

use lib 't/lib';

use Test::DZil;

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          'GatherDir',
          'MakeMaker',
          [ Prereqs => { 'Foo::Bar' => '1.20',      perl => '5.008' } ],
          [ Prereqs => BuildRequires => { 'Builder::Bob' => '9.901' } ],
          [ Prereqs => TestRequires  => { 'Test::Deet'   => '7',
                                          perl           => '5.008' } ],
        ),
      },
    },
  );

  $tzil->build;

  my $makemaker = $tzil->plugin_named('MakeMaker');

  my %want = (
    DISTNAME => 'DZT-Sample',
    NAME     => 'DZT::Sample',
    ABSTRACT => 'Sample DZ Dist',
    VERSION  => '0.001',
    AUTHOR   => 'E. Xavier Ample <example@example.org>',
    LICENSE  => 'perl',

    PREREQ_PM          => {
      'Foo::Bar' => '1.20'
    },
    BUILD_REQUIRES     => {
      'Builder::Bob' => '9.901',
    },
    TEST_REQUIRES      => {
      'Test::Deet'   => '7',
    },
    CONFIGURE_REQUIRES => {
      'ExtUtils::MakeMaker' => '6.30'
    },
    EXE_FILES => [],
    test => { TESTS => 't/*.t' },
  );

  cmp_deeply(
    $makemaker->__write_makefile_args,
    \%want,
    'correct makemaker args generated',
  );
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          'GatherDir',
          'MakeMaker',
          [ Prereqs => { perl => '5.8.1' } ],
        ),
      },
    },
  );

  $tzil->build;

  my $content = $tzil->slurp_file('build/Makefile.PL');

  like($content, qr/^use 5\.008001;\s*$/m, "normalized the perl version needed");
}

done_testing;
