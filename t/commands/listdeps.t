use strict;
use warnings;
use Test::More 0.88;
use Test::Deep;

use Dist::Zilla::App::Tester;

# see also t/plugins/autoprereqs.t
my %prereqs = (
    requires => {
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
    },
    recommends => {
        'Term::ReadLine::Gnu'   => 0,
        'Archive::Tar::Wrapper' => 0.15
    },
    suggests   => {
        'PPI::XS'               => 1.23
    }
);

my %versions;
for my $type (keys %prereqs) {
    @versions{ keys %{$prereqs{$type}} } = values %{$prereqs{$type}};
}

my @default_prereqs = (keys %{$prereqs{requires}}, keys %{$prereqs{recommends}});

note "no args"; {
    my $output = test_dzil('corpus/dist/AutoPrereqs', [ qw(listdeps) ])->output;
    cmp_deeply(
        [ split("\n", $output) ],
        bag(grep { $_ ne 'perl' } @default_prereqs),
        'all prereqs listed as output',
    );
}

note "--no-requires"; {
    my $output = test_dzil('corpus/dist/AutoPrereqs', [ qw(listdeps --no-requires) ])->output;
    cmp_deeply(
        [ split("\n", $output) ],
        bag(grep { $_ ne 'perl' } keys %{$prereqs{recommends}}),
        'no recommended prereqs listed as output',
    );
}

note "--no-recommends"; {
    my $output = test_dzil('corpus/dist/AutoPrereqs', [ qw(listdeps --no-recommends) ])->output;
    cmp_deeply(
        [ split("\n", $output) ],
        bag(grep { $_ ne 'perl' } keys %{$prereqs{requires}}),
        'no recommended prereqs listed as output',
    );
}

note "--suggests"; {
    my $output = test_dzil('corpus/dist/AutoPrereqs', [ qw(listdeps --suggests) ])->output;
    cmp_deeply(
        [ split("\n", $output) ],
        bag(grep { $_ ne 'perl' } @default_prereqs, keys %{$prereqs{suggests}}),
        'no recommended prereqs listed as output',
    );
}

note "--versions"; {
    my $output = test_dzil('corpus/dist/AutoPrereqs', [ qw(listdeps --versions) ])->output;
    cmp_deeply(
        [ split("\n", $output) ],
        bag(map { $_ . ' = ' . $versions{$_} } grep { $_ ne 'perl' } @default_prereqs),
        'prereqs listed with versions for --versions',
    );
}

{
    my $output = test_dzil('corpus/dist/AutoPrereqs', [ qw(listdeps --cpanm-versions) ])->output;
    cmp_deeply(
        [ split("\n", $output) ],
        bag(map { $_ . '~"' . $prereqs{$_} . '"' } grep { $_ ne 'perl' } keys %prereqs),
        'prereqs listed with versions for --cpanm-versions',
    );
}

foreach my $arg (qw(--author --develop))
{
    my $output = test_dzil('corpus/dist/AutoPrereqs', [ 'listdeps', $arg])->output;
    cmp_deeply(
        [ split("\n", $output) ],
        bag('String::Formatter', grep { $_ ne 'perl' } @default_prereqs),
        'develop prereqs included in output for ' . $arg,
    );
}

done_testing;
