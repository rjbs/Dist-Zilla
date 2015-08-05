use strict;
use warnings;
use Test::More 0.88;
use Test::Deep;

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
      'Module::Build' => '0.28',
    },
    test_requires => {
      'Test::Deet'    => '7',
    },
    'configure_requires' => {
      'Module::Build' => '0.28',
    },
    'recursive_test_files' => ignore,
  );

  cmp_deeply(
    $have,
    \%want,
    'module_build_args',
  );

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
        'source/dist.ini' => simple_ini( 'GatherDir', [ 'ModuleBuild' => {
            mb_class      => 'Foo::Build',
            mb_lib        => 'inc,priv,something',
            build_element => [qw(js sql)],
        } ] ),
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
  is(
    $modulebuild->_add_build_elements,
    '$build->add_build_element($_) for qw(js sql);',
    'adds build elements'
  );

  my $build = $tzil->slurp_file('build/Build.PL');

  like($build, qr/\QFoo::Build->new/, 'Build.PL calls ->new on Foo::Build');
  like($build, qr/\$build->add_build_element\(\$_\) for qw\(js sql\);/,
       'Build.PL calls add_build_element for all elements');
}

done_testing;
