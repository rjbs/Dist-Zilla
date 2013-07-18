use strict;
use warnings;
use Test::More 0.88;
use Test::Deep;
use utf8;

use Test::DZil;

use JSON 2;
use YAML::Tiny;

{
  # 2.0
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          'GatherDir',
          [ MetaResources => HomePage => {homepage => 'http://bana.na/phone'}],
          [ MetaResources => License  => {license  => 'http://b.sd/license' }],
          [ Prereqs   => { 'Foo::Bar' => '1.234' } ],
          [ Prereqs   => RuntimeRecommends => { 'Foo::Bar::Opt' => '1.234' } ],
          [ Prereqs   => BuildRequires     => { 'Test::Foo' => '2.34' } ],
          [ Prereqs   => ConfigureRequires => { 'Build::Foo' => '0.12' } ],
          'MetaJSON',
          [ MetaYAML => { version => 2 } ],
          'MetaConfig',
        ),
      },
    },
  );

  $tzil->build;

  my @files = map {; $_->name } @{ $tzil->files };

  my %meta;

  my $json = $tzil->slurp_file('build/META.json');
  $meta{json} = JSON->new->decode($json);

  my $yaml = $tzil->slurp_file('build/META.yml');
  $meta{yaml} = YAML::Tiny->new->read_string($yaml)->[0];

  is_deeply($meta{json}, $meta{yaml}, "META.json is_deeply META.yml");

  for my $type (qw(json yaml)) {
    my $meta = $meta{$type};

    my %want = (
      name      => 'DZT-Sample',
      abstract  => 'Sample DZ Dist',
      author    => [ 'E. Xavier Ample <example@example.org>' ],

      prereqs   => {
        runtime => {
          requires   => { 'Foo::Bar' => '1.234' },
          recommends => { 'Foo::Bar::Opt' => '1.234' },
        },
        build     => { requires => { 'Test::Foo' => '2.34'  } },
        configure => { requires => { 'Build::Foo' => '0.12' } },
      },

      license   => [ 'perl_5' ],
      resources => {
        homepage => 'http://bana.na/phone',
        license  => [ 'http://b.sd/license' ],
      },
      version   => '0.001',
    );

    cmp_deeply(
      $meta,
      superhashof(\%want),
      "2.0 $type data",
    );
  }
}

{
  # 1.4
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          'GatherDir',
          [ MetaResources => HomePage => {homepage => 'http://bana.na/phone'}],
          [ MetaResources => License  => {license  => 'http://b.sd/license' }],
          [ Prereqs   => { 'Foo::Bar' => '1.234' } ],
          [ Prereqs   => RuntimeRecommends => { 'Foo::Bar::Opt' => '1.234' } ],
          [ Prereqs   => BuildRequires     => { 'Test::Foo' => '2.34' } ],
          [ Prereqs   => ConfigureRequires => { 'Build::Foo' => '0.12' } ],
          [ MetaJSON => { version => 1.4 } ],
          'MetaYAML',
          'MetaConfig',
        ),
      },
    },
  );

  $tzil->build;

  my @files = map {; $_->name } @{ $tzil->files };

  my %meta;

  my $json = $tzil->slurp_file('build/META.json');
  $meta{json} = JSON->new->decode($json);

  my $yaml = $tzil->slurp_file('build/META.yml');
  $meta{yaml} = YAML::Tiny->new->read_string($yaml)->[0];

  is_deeply($meta{json}, $meta{yaml}, "META.json is_deeply META.yml");

  for my $type (qw(json yaml)) {
    my $meta = $meta{$type};

    my %want = (
      name      => 'DZT-Sample',
      abstract  => 'Sample DZ Dist',
      author    => [ 'E. Xavier Ample <example@example.org>' ],

      configure_requires => { 'Build::Foo' => '0.12' },
      build_requires     => { 'Test::Foo'  => '2.34' },
      requires   => { 'Foo::Bar' => '1.234' },
      recommends => { 'Foo::Bar::Opt' => '1.234' },

      license   => 'perl',
      resources => {
        homepage => 'http://bana.na/phone',
        license  => 'http://b.sd/license',
      },
      version   => '0.001',
    );

    cmp_deeply(
      $meta,
      superhashof(\%want),
      "1.4 $type data",
    );
  }
}

{ # non-ASCII
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZ-NonAscii' },
  );

  $tzil->build;

  my @files = map {; $_->name } @{ $tzil->files };

  my %meta;

  my $json = $tzil->slurp_file('build/META.json');
  $meta{json} = JSON->new->decode($json);

  my $yaml = $tzil->slurp_file('build/META.yml');
  $meta{yaml} = YAML::Tiny->new->read_string($yaml)->[0];

  for my $type (qw(json yaml)) {
    is_deeply(
      $meta{$type}{author},
      [
        'Olivier Mengué <dolmen@example.org>',
        '김도형 <keedi@example.com>'
      ],
      "authors ($type) are set as expected, decode properly",
    );
  }
}

done_testing;
