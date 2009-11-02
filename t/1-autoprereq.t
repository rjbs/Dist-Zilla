#!perl

use strict;
use warnings;

use Dist::Zilla;
use File::Spec::Functions qw{ catdir catfile };
use Test::More tests => 1;

# build fake dist
chdir( catdir('t', 'foo') );
my $zilla = Dist::Zilla->from_config;
$zilla->build_in;
my $dir = 'Foo-1.23';

# check found prereqs
open my $fh, '<', catfile($dir, 'Makefile.PL') or die $!;
my @lines = grep { /PREREQ_PM/ .. /\}/ } <$fh>;
shift @lines; pop @lines;
my %prereqs = map { eval $_ } @lines;
close $fh;

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
is_deeply( \%prereqs, \%wanted, '')

