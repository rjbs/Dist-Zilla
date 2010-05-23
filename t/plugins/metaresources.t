use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Test::DZil;
use CPAN::Meta::Converter;

my $generated_by = 'Dist::Zilla::Tester version '
  . (Dist::Zilla::Tester->VERSION || '(undef)');

my $converted_by = "$generated_by, CPAN::Meta::Converter version "
                 . CPAN::Meta::Converter->VERSION;

{
  my $tzil = Dist::Zilla::Tester->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [
            'MetaResources' => {
              homepage   => 'http://example.com',
              bugtracker => 'http://bugs.example.com',
              repository => 'git://example.com/project.git',
            },
          ],
          ['MetaYAML'],
          ['MetaJSON'],
        ),
      },
    },
  );

  eval { $tzil->build };
  ok(!$@,
    'no errors from old-style bugtracker and repository for MetaResources');

  is_yaml(
    $tzil->slurp_file('build/META.yml'),
    {
      abstract       => 'Sample DZ Dist',
      author         => ['E. Xavier Ample <example@example.org>'],
      build_requires => {},
      dynamic_config => 0,
      generated_by   => $converted_by,
      license        => 'perl',
      'meta-spec'    => {
        url     => 'http://module-build.sourceforge.net/META-spec-v1.4.html',
        version => '1.4'
      },
      name      => 'DZT-Sample',
      resources => {
        homepage   => 'http://example.com',
        bugtracker => 'http://bugs.example.com',
        repository => 'git://example.com/project.git',
      },
      version => '0.001'
    },
    'META.yml matches expected 1.4 spec output'
  );

  is_json(
    $tzil->slurp_file('build/META.json'),
    {
      abstract       => 'Sample DZ Dist',
      author         => ['E. Xavier Ample <example@example.org>'],
      dynamic_config => 0,
      generated_by   => $generated_by,
      license        => 'perl_5',
      'meta-spec'    => {
        url     => 'http://github.com/dagolden/cpan-meta/',
        version => 2
      },
      name      => 'DZT-Sample',
      prereqs   => {},
      resources => {
        bugtracker => { web => 'http://bugs.example.com' },
        homepage   => 'http://example.com',
        repository => { url => 'git://example.com/project.git' }
      },
      version => '0.001'
    },
    'META.json was 2.0 output, old-style resources were upgraded'
  );
}

{
  my $tzil = Dist::Zilla::Tester->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [
            'MetaResources' => {
              homepage            => 'http://example.com',
              'bugtracker.web'    => 'http://bugs.example.com',
              'bugtracker.mailto' => 'project@bugs.example.com',
              'repository.url'    => 'git://example.com/project.git',
              'repository.web'    => 'http://example.com/git/project',
              'repository.type'   => 'git',
            },
          ],
          ['MetaYAML'],
          ['MetaJSON'],
        ),
      },
    },
  );

  eval { $tzil->build };
  ok(!$@,
    'no errors from new-style bugtracker and repository for MetaResources');

  is_yaml(
    $tzil->slurp_file('build/META.yml'),
    {
      abstract       => 'Sample DZ Dist',
      author         => ['E. Xavier Ample <example@example.org>'],
      build_requires => {},
      dynamic_config => 0,
      generated_by   => $converted_by,
      license        => 'perl',
      'meta-spec'    => {
        url     => 'http://module-build.sourceforge.net/META-spec-v1.4.html',
        version => '1.4'
      },
      name      => 'DZT-Sample',
      resources => {
        homepage   => 'http://example.com',
        bugtracker => 'http://bugs.example.com',
        repository => 'git://example.com/project.git',
      },
      version => '0.001'
    },
    'META.yml matches expected 1.4 spec output, new style resources were down-graded'
  );

  is_json(
    $tzil->slurp_file('build/META.json'),
    {
      abstract       => 'Sample DZ Dist',
      author         => ['E. Xavier Ample <example@example.org>'],
      dynamic_config => 0,
      generated_by   => $generated_by,
      license        => 'perl_5',
      'meta-spec'    => {
        url     => 'http://github.com/dagolden/cpan-meta/',
        version => 2
      },
      name      => 'DZT-Sample',
      prereqs   => {},
      resources => {
        bugtracker => {
          web    => 'http://bugs.example.com',
          mailto => 'project@bugs.example.com',
        },
        homepage   => 'http://example.com',
        repository => {
          type => 'git',
          url  => 'git://example.com/project.git',
          web  => 'http://example.com/git/project',
        }
      },
      version => '0.001'
    },
    'META.json was 2.0 output'
  );
}

done_testing;
