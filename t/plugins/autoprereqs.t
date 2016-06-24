use strict;
use warnings;

use Test::More 0.88;
use Test::Deep;

use Test::DZil;
use YAML::Tiny;

sub build_meta {
  my $tzil = shift;

  $tzil->build;
  $tzil->distmeta;
}

my $tzil = Builder->from_config(
  { dist_root => 'corpus/dist/AutoPrereqs' },
  { },
);

# check found prereqs
my $meta = build_meta($tzil);

my %want_runtime = (
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
  'base'                  => 0,
  'lib'                   => 0,
  'parent'                => 0,
  'perl'                  => 5.008,
  'strict'                => 0,
  'warnings'              => 0,
);

is_deeply(
  $meta->{prereqs}{runtime}{requires},
  \%want_runtime,
  'all requires found, but no more',
);

# Try again with configure_finder:
$tzil = Builder->from_config(
  { dist_root => 'corpus/dist/AutoPrereqs' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        qw(GatherDir ExecDir),
        [ AutoPrereqs => { skip             => '^DZPA::Skip',
                           configure_finder => ':IncModules' } ],
      ),
      'source/inc/DZPA.pm' => "use DZPA::NotInDist;\n use DZPA::Configure;\n",
    },
  },
);

# check found prereqs
$meta = build_meta($tzil);

is_deeply(
  $meta->{prereqs}{runtime}{requires},
  \%want_runtime,
  'configure_finder did not change runtime requires',
);

my %want_configure = (
  'DZPA::Configure'       => 0,
  'DZPA::NotInDist'       => 0,
);

is_deeply(
  $meta->{prereqs}{configure}{requires},
  \%want_configure,
  'configure_requires is correct',
);


# Try again with tests added to the dist:
$tzil = Builder->from_config(
  { dist_root => 'corpus/dist/AutoPrereqs' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        qw(GatherDir ExecDir),
        [ AutoPrereqs => { skip             => '^DZPA::Skip',
                           configure_finder => ':IncModules' } ],
      ),
      'source/inc/DZPA.pm' => "use DZPA::NotInDist;\n use DZPA::Configure;\n",
      'source/t/basic.t' => "use Test::Foo;\n",
    },
  },
);

# check found prereqs
$meta = build_meta($tzil);

my %want_test = (
  'Test::Foo'  => '0',
);

cmp_deeply(
  $meta,
  superhashof({
    prereqs => {
      runtime => { requires => \%want_runtime },
      configure => { requires => \%want_configure },
      test => { requires => \%want_test },
    },
  }),
  'test_finder did not change runtime, configure requires; test requires is correct',
);


# Try again with extra tests added to the dist:
$tzil = Builder->from_config(
  { dist_root => 'corpus/dist/AutoPrereqs' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        qw(GatherDir ExecDir),
        [ AutoPrereqs => { skip             => '^DZPA::Skip',
                           configure_finder => ':IncModules' } ],
      ),
      'source/inc/DZPA.pm' => "use DZPA::NotInDist;\n use DZPA::Configure;\n",
      'source/t/basic.t' => "use Test::Foo;\n",
      'source/xt/author/more1.t' => "use Test::Bar;\n",
      'source/xt/smoke/more2.t' => "use Test::Baz;\n",
      'source/xt/release/more3.t' => "use Test::Qux;\n",
      'source/xt/more4.t' => "use Test::Norf;\n",
    },
  },
);

# check found prereqs
$meta = build_meta($tzil);

my %want_develop = (
  'Test::Bar'  => '0',
  'Test::Baz'  => '0',
  'Test::Qux'  => '0',
  'Test::Norf' => '0',
);

cmp_deeply(
  $meta,
  superhashof({
    prereqs => {
      runtime => { requires => \%want_runtime },
      configure => { requires => \%want_configure },
      test => { requires => \%want_test },
      develop => { requires => \%want_develop },
    },
  }),
  'develop_finder did not change runtime, configure, test requires; develop requires is correct',
);


# Try again with a customized scanner list:
$tzil = Builder->from_config(
  { dist_root => 'corpus/dist/AutoPrereqs' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        qw(GatherDir ExecDir),
        [ AutoPrereqs => { scanner => 'Perl5', extra_scanner => 'Aliased' } ],
      ),
      'source/lib/DZPA/Aliased.pm' => "use aliased 'Long::Class::Name';\n",
    },
  },
);

# check found prereqs
$meta = build_meta($tzil);

{
my %want_runtime = %want_runtime;
# Moose-style prereqs should not be recognized this time:
delete $want_runtime{'DZPA::Base::Moose1'};
delete $want_runtime{'DZPA::Base::Moose2'};
delete $want_runtime{'DZPA::Role'};

$want_runtime{'DZPA::Skip::Blah'}  = 0; # not skipping anymore
$want_runtime{'DZPA::Skip::Foo'}   = 0;
$want_runtime{'aliased'}           = 0;
$want_runtime{'Long::Class::Name'} = 0;

is_deeply(
  $meta->{prereqs}{runtime}{requires},
  \%want_runtime,
  'custom scanner list',
);
}


# Try again with a non-default prereq type:
$tzil = Builder->from_config(
  { dist_root => 'corpus/dist/AutoPrereqs' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        qw(GatherDir ExecDir),
        [ AutoPrereqs => { skip             => '^DZPA::Skip',
                           type             => 'suggests' } ],
      ),
      'source/t/basic.t' => "use Test::Foo;\n",
    },
  },
);

# check found prereqs
$meta = build_meta($tzil);

cmp_deeply(
  $meta,
  superhashof({
    prereqs => {
      runtime => { suggests => \%want_runtime },
      test => { suggests => \%want_test },
    },
  }),
  'all prereqs were added with the "suggests" relationship',
);

done_testing;
