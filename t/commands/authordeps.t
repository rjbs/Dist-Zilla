use strict;
use warnings;
use Test::More 0.88;
use Test::Deep;

use autodie;

use Dist::Zilla::Util::AuthorDeps;

my $authordeps =
    Dist::Zilla::Util::AuthorDeps::extract_author_deps(
	'corpus/dist/AuthorDeps',
	0
    );

cmp_deeply(
    $authordeps,
    [
      +{ perl => '5.005' },
      +{ 'List::MoreUtils' => '0.407' },
      +{ 'Foo::Bar' => '1.23' },
      +{ 'Dist::Zilla' => '5.001' },
      ( map { +{"Dist::Zilla::Plugin::$_" => '5.0'} } qw<AutoPrereqs Encoding ExecDir> ),
      ( map { +{"Dist::Zilla::Plugin::$_" => 0} } qw<GatherDir MetaYAML> ),
      +{ 'Software::License::Perl_5' => '0' },
    ],
    "authordeps in corpus/dist/AuthorDeps"
) or diag explain $authordeps;

done_testing;
