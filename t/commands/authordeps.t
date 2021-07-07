use strict;
use warnings;
use Test::More 0.88;
use Test::Deep;

use autodie;

use Dist::Zilla::Util::AuthorDeps;

my $authordeps = Dist::Zilla::Util::AuthorDeps::extract_author_deps(
  'corpus/dist/AuthorDeps',
  0,
);

cmp_deeply(
  $authordeps,
  [
    +{ perl => '5.005' },
    +{ 'List::Util' => '1.45' },
    +{ 'Foo::Bar' => '1.23' },
    +{ 'Dist::Zilla' => '5.001' },
    ( map { +{"Dist::Zilla::Plugin::$_" => '5.0'} } qw<AutoPrereqs Encoding ExecDir> ),
    ( map { +{"Dist::Zilla::Plugin::$_" => 0} } qw<GatherDir MetaYAML> ),
    +{ 'LocalPlugin' => '0' },
    +{ 'Software::License::Perl_5' => '0' },
  ],
  "authordeps in corpus/dist/AuthorDeps"
) or diag explain $authordeps;

SKIP: {

  skip 'this test requires the local plugins to have a $VERSION assigned', 1
    if not eval { require Dist::Zilla::Plugin::Encoding; Dist::Zilla::Plugin::Encoding->VERSION('5.000'); 1 };

  my $missing_authordeps = Dist::Zilla::Util::AuthorDeps::extract_author_deps(
    'corpus/dist/AuthorDeps',
    1
  );

  cmp_deeply(
    $missing_authordeps,
    [
      +{ 'Foo::Bar' => '1.23' },
    ],
    "missing authordeps in corpus/dist/AuthorDeps"
  ) or diag explain $missing_authordeps;
}

done_testing;
