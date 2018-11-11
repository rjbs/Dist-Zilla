use strict;
use warnings;
use Test::More 0.88;

use Test::DZil;
use Test::Deep;
use CPAN::Meta::Converter;

my $generated_by = 'Dist::Zilla::Tester version '
  . (Builder->VERSION || '(undef)');

my $converted_by = "CPAN::Meta::Converter version "
                 . CPAN::Meta::Converter->VERSION;

my $generated_by_re = qr/\A\Q$generated_by\E(?:, \Q$converted_by\E)?\z/;

my $serialization_yaml = 'YAML::Tiny version ' . YAML::Tiny->VERSION;
my $json_backend = JSON::MaybeXS::JSON();
my $serialization_json = $json_backend . ' version ' . $json_backend->VERSION;

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
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
      generated_by   => re($generated_by_re),
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
      version => '0.001',
      x_generated_by_perl => "$^V",
      x_serialization_backend => $serialization_yaml,
      x_spdx_expression => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    },
    'META.yml matches expected 1.4 spec output'
  );

  is_json(
    $tzil->slurp_file('build/META.json'),
    {
      abstract       => 'Sample DZ Dist',
      author         => ['E. Xavier Ample <example@example.org>'],
      dynamic_config => 0,
      generated_by   => re($generated_by_re),
      license        => [ 'perl_5' ],
      'meta-spec'    => {
        url     => re(qr/^http.*CPAN::Meta::Spec$/),
        version => 2
      },
      name      => 'DZT-Sample',
      prereqs   => {},
      release_status => 'stable',
      resources => {
        bugtracker => { web => 'http://bugs.example.com' },
        homepage   => 'http://example.com',
        repository => superhashof({ url => 'git://example.com/project.git' }),
      },
      version => '0.001',
      x_generated_by_perl => "$^V",
      x_serialization_backend => $serialization_json,
      x_spdx_expression => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    },
    'META.json was 2.0 output, old-style resources were upgraded'
  );
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
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
      generated_by   => re($generated_by_re),
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
      version => '0.001',
      x_generated_by_perl => "$^V",
      x_serialization_backend => $serialization_yaml,
      x_spdx_expression => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    },
    'META.yml matches expected 1.4 spec output, new style resources were down-graded'
  );

  is_json(
    $tzil->slurp_file('build/META.json'),
    {
      abstract       => 'Sample DZ Dist',
      author         => ['E. Xavier Ample <example@example.org>'],
      dynamic_config => 0,
      generated_by   => re($generated_by_re),
      license        => [ 'perl_5' ],
      'meta-spec'    => {
        url     => re(qr/^http.*CPAN::Meta::Spec$/),
        version => 2
      },
      name      => 'DZT-Sample',
      prereqs   => {},
      release_status => 'stable',
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
      version => '0.001',
      x_generated_by_perl => "$^V",
      x_serialization_backend => $serialization_json,
      x_spdx_expression => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    },
    'META.json was 2.0 output'
  );
}

done_testing;
