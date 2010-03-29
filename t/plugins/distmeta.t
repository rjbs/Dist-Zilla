use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Test::DZil;

use JSON 2;
use YAML::Tiny;

my $tzil = Dist::Zilla::Tester->from_config(
  { dist_root => 'corpus/DZT' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        'GatherDir',
        [ MetaResources => HomePage => { homepage => 'http://bana.na/phone' } ],
        [ MetaResources => License  => { license  => 'http://b.sd/license'  } ],
        [ Prereq   => { 'Foo::Bar' => '1.234' } ],
        [ Prereq   => RuntimeRecommends => { 'Foo::Bar::Opt' => '1.234' } ],
        [ Prereq   => BuildRequires     => { 'Test::Foo' => '2.34' } ],
        [ Prereq   => ConfigureRequires => { 'Build::Foo' => '0.12' } ],
        'MetaJSON',
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
    requires  => { 'Foo::Bar' => '1.234' },
    recommends => { 'Foo::Bar::Opt' => '1.234' },
    build_requires => { 'Test::Foo' => '2.34' },
    configure_requires => { 'Build::Foo' => '0.12' },
    license   => 'perl',
    resources => {
      homepage => 'http://bana.na/phone',
      license  => 'http://b.sd/license',
    },
    version   => '0.001',
  );

  for my $key (sort keys %want) {
    is_deeply($meta->{ $key }, $want{ $key }, "$key is what we want in $type");
  }
}

done_testing;
