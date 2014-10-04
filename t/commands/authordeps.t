use strict;
use warnings;
use Test::More 0.88 tests => 1;

use lib 't/lib';

use autodie;

use Dist::Zilla::Util::AuthorDeps;
use Path::Class;

my $authordeps =
    Dist::Zilla::Util::AuthorDeps::extract_author_deps(
	dir('corpus/dist/AuthorDeps'),
	0
    );

is_deeply(
    $authordeps,
    [
      +{ perl => '5.005' },
      ( map { +{"Dist::Zilla::Plugin::$_" => '5.0'} } qw<AutoPrereqs Encoding ExecDir> ),
      ( map { +{"Dist::Zilla::Plugin::$_" => 0} } qw<GatherDir MetaYAML> ),
    ],
    "authordeps in corpus/dist/AuthorDeps"
) or diag explain $authordeps;

done_testing;
