use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Test::DZil;

{
  my $tzil = Dist::Zilla::Tester->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          'GatherDir',
          'MakeMaker',
          [ Prereq => { 'Foo::Bar' => '1.20' } ],
          [ Prereq => BuildRequires => { 'Builder::Bob' => '9.901' } ],
          [ Prereq => TestRequires  => { 'Test::Deet'   => '7'     } ],
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
      'Test::Deet'   => '7',
    },
    CONFIGURE_REQUIRES => {
      'ExtUtils::MakeMaker' => '6.11'
    },
  );

  for my $key (sort keys %want) {
    is_deeply(
      $makemaker->__write_makefile_args->{ $key },
      $want{ $key },
      "correct value set for $key",
    );
  }
}

done_testing;
