use strict;
use warnings;
use Test::More 0.88;
use Test::Deep;

use Dist::Zilla::App::Tester;

# see also t/plugins/autoprereqs.t
my %prereqs = (
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

{
    my $output = test_dzil('corpus/dist/AutoPrereqs', [ qw(listdeps) ])->output;
    cmp_deeply(
        [ split("\n", $output) ],
        bag(grep { $_ ne 'perl' } keys %prereqs),
        'all prereqs listed as output',
    );
}

{
    my $output = test_dzil('corpus/dist/AutoPrereqs', [ qw(listdeps --versions) ])->output;
    cmp_deeply(
        [ split("\n", $output) ],
        bag(map { $_ . ' = ' . $prereqs{$_} } grep { $_ ne 'perl' } keys %prereqs),
        'prereqs listed with versions for --versions',
    );
}

{
    my $output = test_dzil('corpus/dist/AutoPrereqs', [ qw(listdeps --author)])->output;
    cmp_deeply(
        [ split("\n", $output) ],
        bag('String::Formatter', grep { $_ ne 'perl' } keys %prereqs),
        'develop prereqs included in output for --author',
    );
}

done_testing;
