use strict;
use warnings;
use Test::More 0.88;
use Test::Deep;
use Test::Fatal;

use Test::DZil;

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          'GatherDir',
          'MakeMaker',
          [ Prereqs => { 'Foo::Bar' => '1.20',
                          perl      => '5.008',
                          Baz       => '1.2.3',
                          Buzz      => 'v1.2' } ],
          [ Prereqs => BuildRequires => { 'Builder::Bob' => '9.901' } ],
          [ Prereqs => TestRequires  => { 'Test::Deet'   => '7',
                                          perl           => '5.008' } ],
          [ Prereqs => ConfigureRequires => { perl => '5.010' } ],
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
    MIN_PERL_VERSION => '5.010',
    test => { TESTS => 't/*.t' },

    PREREQ_PM          => {
      'Foo::Bar' => '1.20',
      'Baz'      => '1.2.3',
      'Buzz'     => '1.2.0',
    },
    BUILD_REQUIRES     => {
      'Builder::Bob' => '9.901',
    },
    TEST_REQUIRES      => {
      'Test::Deet'   => '7',
    },
    CONFIGURE_REQUIRES => {
      'ExtUtils::MakeMaker' => '0'
    },
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
          [ 'MakeMaker', { main_module => "DZT::Main" } ],
        ),
      },
    },
  );

  $tzil->build;

  my $makemaker = $tzil->plugin_named('MakeMaker');

  my %want = (
    DISTNAME => 'DZT-Sample',
    NAME     => 'DZT::Main',
    ABSTRACT => 'Sample DZ Dist',
    VERSION  => '0.001',
    AUTHOR   => 'E. Xavier Ample <example@example.org>',
    LICENSE  => 'perl',
    test => { TESTS => 't/*.t' },
    PREREQ_PM => { },
    CONFIGURE_REQUIRES => {
      'ExtUtils::MakeMaker' => '0'
    },
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
          [ Prereqs => BuildRequires => { 'Builder::Bob' => 0 } ],
          [ Prereqs => TestRequires => { 'Tester::Bob' => 0 } ],
          [ Prereqs => RuntimeRequires => { 'Runner::Bob' => 0 } ],
        ),
      },
    },
  );

  $tzil->build;

  my $content = $tzil->slurp_file('build/Makefile.PL');

  like($content, qr/^use 5\.008001;\s*$/m, "normalized the perl version needed");

  $content =~ m'^my %FallbackPrereqs = \(\n([^;]+)^\);$'mg;

  like($1, qr'"Builder::Bob" => ', 'build-requires prereqs made it into %FallbackPrereqs');
  like($1, qr'"Tester::Bob" => ', 'test-requires prereqs made it into %FallbackPrereqs');
  like($1, qr'"Runner::Bob" => ', 'runtime-requires prereqs made it into %FallbackPrereqs');
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          'GatherDir',
          'MakeMaker',
          [ Prereqs => { 'External::Module' => '<= 1.23' } ],
        ),
        'source/lib/Foo.pm' => "package Foo;\n1\n",
      },
    },
  );

  like(
    exception { $tzil->build },
    qr/\Q[MakeMaker] found version range in runtime prerequisites, which ExtUtils::MakeMaker cannot parse (must specify eumm_version of at least 7.1101): External::Module <= 1.23\E/,
    'build does not permit passing unparsable version range',
  );

  diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          'GatherDir',
          [ 'MakeMaker' => { eumm_version => '7.12' } ],
          [ Prereqs => { 'External::Module' => '<= 1.23' } ],
        ),
        'source/lib/Foo.pm' => "package Foo;\n1\n",
      },
    },
  );

  $tzil->chrome->logger->set_debug(1);
  is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
  );

  ok(
    !(grep { m'[MakeMaker] found version range' } @{ $tzil->log_messages }),
    'got no warning about probably-unparsable version range',
  );

  diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;
}

done_testing;
