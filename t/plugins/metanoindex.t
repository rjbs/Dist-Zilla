use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::DZil;

my %TEST_ATTR = (
  files => {
    values  => [ qw(My/Module.pm My/Module2.pm) ],
    aliases => [ qw(files) ],
  },
  directories => {
    values  => [ qw(My/Private My/Private2) ],
    aliases => [ qw(dir directory folder) ],
  },
  packages => {
    values  => [ qw(My::Module::Stuff My::Module::Things) ],
    aliases => [ qw(class module package) ],
  },
  namespaces => {
    values  => [ qw(My::Module::Stuff My::Module::Things)],
    aliases => [ qw(namespace) ],
  },
);


my $tzil = Builder->from_config(
  { dist_root => 'corpus/dist/DZT' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        [
          MetaNoIndex => {
            file  => 'file-1.txt',
            files => 'file-2.txt',

            dir         => 'dir-1',
            directory   => 'dir-2',
            directories => 'dir-3',
            folder      => 'dir-4',

            package  => 'Package::1',
            packages => 'Package::2',
            class    => 'Class::1',
            module   => 'Module::1',

            namespace  => 'Namespace::1',
            namespaces => 'Namespaces::1',
          },
        ],
      ),
    },
  },
);

$tzil->build;

cmp_deeply(
  $tzil->distmeta,
  superhashof({ no_index => {
    file      => bag(qw(file-1.txt file-2.txt)),
    directory => bag(qw(dir-1 dir-2 dir-3 dir-4)),
    package   => bag(qw(Package::1 Package::2 Class::1 Module::1)),
    namespace => bag(qw(Namespace::1 Namespaces::1)),
  }}),
  "we generated the no_index entry we expected",
);

done_testing;
