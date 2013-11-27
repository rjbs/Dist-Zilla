# Test the FileFinder::ByName and FileFinder::Filter plugins
use strict;
use warnings;

use Test::More 0.88;            # done_testing

use Test::DZil qw(Builder simple_ini is_filelist);
use Dist::Zilla::File::InMemory;

my $tzil;

my @dist_files = map { Dist::Zilla::File::InMemory->new(
                         name => $_, content => '') } qw(
  Changes
  LICENSE
  MANIFEST
  META.json
  META.yml
  Makefile.PL
  README
  Template_strict.patch
  bin/foo.pl
  bin/.hidden/foo.pl
  corpus/DZT/README
  corpus/DZT/lib/DZT/Sample.pm
  corpus/DZT/t/basic.t
  corpus/README
  corpus/archives/DZT-Sample-0.01.tar.gz
  corpus/archives/DZT-Sample-0.02.tar.gz
  corpus/archives/DZT-Sample-0.03.tar.gz
  corpus/gitvercheck.git
  lib/Dist/Zilla/Plugin/ArchiveRelease.pm
  lib/Dist/Zilla/Plugin/FindFiles.pm
  lib/Dist/Zilla/Plugin/GitVersionCheckCJM.pm
  lib/Dist/Zilla/Plugin/Metadata.pm
  lib/Dist/Zilla/Plugin/ModuleBuild/Custom.pm
  lib/Dist/Zilla/Plugin/TemplateCJM.pm
  lib/Dist/Zilla/Plugin/VersionFromModule.pm
  lib/Dist/Zilla/Role/ModuleInfo.pm
  t/00-compile.t
  t/arcrel.t
  t/gitvercheck.t
  t/mb_custom.t
  t/metadata.t
  t/release-pod-coverage.t
  t/release-pod-syntax.t
  t/template.t
  t/vermod.t
);

#---------------------------------------------------------------------
sub is_found {
  my ($plugin, $want, $comment) = @_;

  my $have = $tzil->plugin_named($plugin)->find_files;

  #printf "  %s\n", $_->name for @$have;

  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is_filelist($have, $want, $comment || $plugin);
}

#---------------------------------------------------------------------
sub make_tzil {
  $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(@_),
      },
    },
  );

  # Don't bother building anything, we just need a list of filenames:
  @{ $tzil->files } = @dist_files;
}

#---------------------------------------------------------------------
make_tzil([ 'FileFinder::ByName' => {qw(dir corpus  skip archives)}],
          [ 'FileFinder::Filter' => {qw(finder FileFinder::ByName  skip DZT)}]);

is_found('FileFinder::ByName' => [qw(
  corpus/DZT/README
  corpus/DZT/lib/DZT/Sample.pm
  corpus/DZT/t/basic.t
  corpus/README
  corpus/gitvercheck.git
)], 'dir corpus skip archives');

is_found('FileFinder::Filter' => [qw(
  corpus/README
  corpus/gitvercheck.git
)], 'filter DZT');

#---------------------------------------------------------------------
make_tzil(
  [ 'FileFinder::ByName' => InBin => {qw(dir bin)}],
  [ 'FileFinder::ByName' => AllPerl => { file => [qw( *.pl *.pm)] }],
  [ 'FileFinder::ByName' => Plugins => {qw( dir lib  match \.pm$  skip /Role/)}],
  [ 'FileFinder::ByName' => Synopsis => { file => '*.pl',
                                          dir  => [qw(bin lib)],
                                          match => '\.pm$',
                                          skip  => '(?i)version' }],
  [ 'FileFinder::Filter' => Everything =>
    { finder => [qw(InBin AllPerl Plugins Synopsis)] }],
  [ 'FileFinder::Filter' => NoPluginM =>
    { finder => 'AllPerl', skip => 'Plugin/M' }],
);

is_found(InBin => [qw(
  bin/foo.pl
  bin/.hidden/foo.pl
)]);

is_found(AllPerl => [qw(
  bin/foo.pl
  bin/.hidden/foo.pl
  corpus/DZT/lib/DZT/Sample.pm
  lib/Dist/Zilla/Plugin/ArchiveRelease.pm
  lib/Dist/Zilla/Plugin/FindFiles.pm
  lib/Dist/Zilla/Plugin/GitVersionCheckCJM.pm
  lib/Dist/Zilla/Plugin/Metadata.pm
  lib/Dist/Zilla/Plugin/ModuleBuild/Custom.pm
  lib/Dist/Zilla/Plugin/TemplateCJM.pm
  lib/Dist/Zilla/Plugin/VersionFromModule.pm
  lib/Dist/Zilla/Role/ModuleInfo.pm
)]);

is_found(Plugins => [qw(
  lib/Dist/Zilla/Plugin/ArchiveRelease.pm
  lib/Dist/Zilla/Plugin/FindFiles.pm
  lib/Dist/Zilla/Plugin/GitVersionCheckCJM.pm
  lib/Dist/Zilla/Plugin/Metadata.pm
  lib/Dist/Zilla/Plugin/ModuleBuild/Custom.pm
  lib/Dist/Zilla/Plugin/TemplateCJM.pm
  lib/Dist/Zilla/Plugin/VersionFromModule.pm
)]);

is_found(Synopsis => [qw(
  bin/foo.pl
  bin/.hidden/foo.pl
  lib/Dist/Zilla/Plugin/ArchiveRelease.pm
  lib/Dist/Zilla/Plugin/FindFiles.pm
  lib/Dist/Zilla/Plugin/Metadata.pm
  lib/Dist/Zilla/Plugin/ModuleBuild/Custom.pm
  lib/Dist/Zilla/Plugin/TemplateCJM.pm
  lib/Dist/Zilla/Role/ModuleInfo.pm
)]);

is_found(Everything => [qw(
  bin/foo.pl
  bin/.hidden/foo.pl
  corpus/DZT/lib/DZT/Sample.pm
  lib/Dist/Zilla/Plugin/ArchiveRelease.pm
  lib/Dist/Zilla/Plugin/FindFiles.pm
  lib/Dist/Zilla/Plugin/GitVersionCheckCJM.pm
  lib/Dist/Zilla/Plugin/Metadata.pm
  lib/Dist/Zilla/Plugin/ModuleBuild/Custom.pm
  lib/Dist/Zilla/Plugin/TemplateCJM.pm
  lib/Dist/Zilla/Plugin/VersionFromModule.pm
  lib/Dist/Zilla/Role/ModuleInfo.pm
)]);

is_found(NoPluginM => [qw(
  bin/foo.pl
  bin/.hidden/foo.pl
  corpus/DZT/lib/DZT/Sample.pm
  lib/Dist/Zilla/Plugin/ArchiveRelease.pm
  lib/Dist/Zilla/Plugin/FindFiles.pm
  lib/Dist/Zilla/Plugin/GitVersionCheckCJM.pm
  lib/Dist/Zilla/Plugin/TemplateCJM.pm
  lib/Dist/Zilla/Plugin/VersionFromModule.pm
  lib/Dist/Zilla/Role/ModuleInfo.pm
)]);

#---------------------------------------------------------------------
make_tzil([ 'FileFinder::ByName' => 'Everything' ],
          [ 'FileFinder::ByName' => 'EverythingButPerl' =>
            {skip => [qw( \.t$ (?i)\.p[lm]$ )]} ]);

is_found(Everything => [ map { $_->name } @dist_files ]);

is_found(EverythingButPerl => [qw(
  Changes
  LICENSE
  MANIFEST
  META.json
  META.yml
  README
  Template_strict.patch
  corpus/DZT/README
  corpus/README
  corpus/archives/DZT-Sample-0.01.tar.gz
  corpus/archives/DZT-Sample-0.02.tar.gz
  corpus/archives/DZT-Sample-0.03.tar.gz
  corpus/gitvercheck.git
)]);

done_testing;
