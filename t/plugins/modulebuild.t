use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Test::DZil;

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          'GatherDir',
          'ModuleBuild',
          [ Prereqs => { 'Foo::Bar' => '1.20' } ],
          [ Prereqs => BuildRequires => { 'Builder::Bob' => '9.901' } ],
          [ Prereqs => TestRequires  => { 'Test::Deet'   => '7'     } ],
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
      'Builder::Bob'  => '9.901',
      'Module::Build' => '0.3601',
      'Test::Deet'    => '7',
    },
    'configure_requires' => {
      'Module::Build' => '0.3601',
    },
  );

  for my $key (sort keys %want) {
    is_deeply(
      $have->{ $key },
      $want{ $key },
      "correct value set for $key",
    );
  }

  is($modulebuild->_use_custom_class, q{}, 'no custom class by default');
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          'GatherDir', [ 'ModuleBuild' => { mb_class => 'Foo::Build' } ],
        ),
      },
    },
  );

  $tzil->build;

  my $modulebuild = $tzil->plugin_named('ModuleBuild');

  is(
    $modulebuild->_use_custom_class,
    q{use lib qw{inc}; use Foo::Build;},
    'loads custom class from inc'
  );

  my $build = $tzil->slurp_file('build/Build.PL');

  like($build, qr/\QFoo::Build->new/, 'Build.PL calls ->new on Foo::Build');
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          'GatherDir', [ 'ModuleBuild' => { mb_class => 'Foo::Build', mb_lib => 'inc,priv,something' } ],
        ),
      },
    },
  );

  $tzil->build;

  my $modulebuild = $tzil->plugin_named('ModuleBuild');

  is(
    $modulebuild->_use_custom_class,
    q{use lib qw{inc priv something}; use Foo::Build;},
    'loads custom class from items specificed in mb_lib'
  );

  my $build = $tzil->slurp_file('build/Build.PL');

  like($build, qr/\QFoo::Build->new/, 'Build.PL calls ->new on Foo::Build');
}

done_testing;
