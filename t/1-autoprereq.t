#!perl

use strict;
use warnings;

use Dist::Zilla;
use Path::Class;
use Test::More tests => 1;
use YAML       qw{ LoadFile };


# build fake dist
chdir( dir('t', 'foo') );
my $zilla = Dist::Zilla->from_config;
$zilla->build_in;
my $dir = dir('Foo-1.23');

# check found prereqs
my $meta = LoadFile( $dir->file('META.yml') );
my %wanted = (
    'DZPA::Base'            => 0,
    'DZPA::IndentedRequire' => '3.45',
    'DZPA::IndentedUse'     => '0.13',
    'DZPA::MinVerComment'   => '0.50',
    'DZPA::ModRequire'      => 0,
    'DZPA::NotInDist'       => 0,
    'DZPA::Role'            => 0,
    'DZPA::ScriptUse'       => 0,
    'perl'                  => 5.008,
);
is_deeply( $meta->{requires}, \%wanted, 'all requires found, but no more' );

# clean after ourselves
$dir->rmtree;
