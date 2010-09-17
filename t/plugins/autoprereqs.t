#!perl
use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Test::DZil;
use YAML::Tiny;

my $tzil = Builder->from_config(
  { dist_root => 'corpus/dist/AutoPrereqs' },
  { },
);

$tzil->build;

# check found prereqs
my $meta = YAML::Tiny->new->read($tzil->tempdir->file('build/META.yml'))->[0];

my %wanted = (
  # DZPA::Main should not be extracted
  'DZPA::Base::Moose1'    => 0,
  'DZPA::Base::Moose2'    => 0,
  'DZPA::Base::base1'     => 0,
  'DZPA::Base::base2'     => 0,
  'DZPA::Base::base3'     => 0,
  'DZPA::Base::parent1'   => 0,
  'DZPA::Base::parent2'   => 0,
  'DZPA::Base::parent3'   => 0,
  'DZPA::IgnoreAPI'       => 0,
  'DZPA::IndentedRequire' => '3.45',
  'DZPA::IndentedUse'     => '0.13',
  'DZPA::MinVerComment'   => '0.50',
  'DZPA::ModRequire'      => 0,
  'DZPA::NotInDist'       => 0,
  'DZPA::Role'            => 0,
  'DZPA::ScriptUse'       => 0,
  'parent'                => 0,
  'perl'                  => 5.008,
);

is_deeply(
  $meta->{prereqs}{runtime}{requires},
  \%wanted,
  'all requires found, but no more',
);

done_testing;
