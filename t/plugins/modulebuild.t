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
          'AllFiles',
          'ModuleBuild',
          [ Prereq => { 'Foo::Bar' => '1.20' } ],
          [ Prereq => BuildRequires => { 'Builder::Bob' => '9.901' } ],
          [ Prereq => TestRequires  => { 'Test::Deet'   => '7'     } ],
        ),
      },
    },
  );

  $tzil->build;

  my $modulebuild = $tzil->plugin_named('ModuleBuild');

  my $have = $modulebuild->__module_build_args;

  my %want = (
    'module_name'   => 'DZT::Sample',
    'dist_name'     => 'DZT-Sample',
    'dist_abstract' => 'Sample DZ Dist',
    'dist_version'  => '0.001',
    'dist_author'   => [
      'E. Xavier Ample <example@example.org>'
    ],
    'license'       => 'perl',

    'requires' => {
      'Foo::Bar' => '1.20'
    },
    build_requires => {
      'Builder::Bob' => '9.901',
      'Test::Deet'   => '7'
    },
    'configure_requires' => {},
  );

  for my $key (sort keys %want) {
    is_deeply(
      $have->{ $key },
      $want{ $key },
      "correct value set for $key",
    );
  }
}

done_testing;
