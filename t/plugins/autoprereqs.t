use strict;
use warnings;

use Test::More 0.88;

use Test::DZil;
use YAML::Tiny;

sub build_meta {
  my $tzil = shift;

  $tzil->build;

  YAML::Tiny->new->read($tzil->tempdir->file('build/META.yml'))->[0];
}

my $tzil = Builder->from_config(
  { dist_root => 'corpus/dist/AutoPrereqs' },
  { },
);

# check found prereqs
my $meta = build_meta($tzil);

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
  'base'                  => 0,
  'lib'                   => 0,
  'parent'                => 0,
  'perl'                  => 5.008,
  'strict'                => 0,
  'warnings'              => 0,
);

is_deeply(
  $meta->{prereqs}{runtime}{requires},
  \%wanted,
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
        [ MetaYAML => { version => 2 } ],
      ),
      'source/inc/DZPA.pm' => "use DZPA::NotInDist;\n use DZPA::Configure;\n",
    },
  },
);

# check found prereqs
$meta = build_meta($tzil);

is_deeply(
  $meta->{prereqs}{runtime}{requires},
  \%wanted,
  'configure_finder did not change requires',
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

# Try again with a customized scanner list:
$tzil = Builder->from_config(
  { dist_root => 'corpus/dist/AutoPrereqs' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        qw(GatherDir ExecDir),
        [ AutoPrereqs => { scanner => 'Perl5', extra_scanner => 'Aliased' } ],
        [ MetaYAML => { version => 2 } ],
      ),
      'source/lib/DZPA/Aliased.pm' => "use aliased 'Long::Class::Name';\n",
    },
  },
);

# check found prereqs
$meta = build_meta($tzil);

# Moose-style prereqs should not be recognized this time:
delete $wanted{'DZPA::Base::Moose1'};
delete $wanted{'DZPA::Base::Moose2'};
delete $wanted{'DZPA::Role'};

$wanted{'DZPA::Skip::Blah'}  = 0; # not skipping anymore
$wanted{'DZPA::Skip::Foo'}   = 0;
$wanted{'aliased'}           = 0;
$wanted{'Long::Class::Name'} = 0;

is_deeply(
  $meta->{prereqs}{runtime}{requires},
  \%wanted,
  'custom scanner list',
);

done_testing;
