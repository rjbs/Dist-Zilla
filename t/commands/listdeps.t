use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Dist::Zilla::App::Tester;
use Test::DZil;
use Test::File;
use Path::Class;

## cribbed from t/tester-demo.t

$ENV{DZIL_GLOBAL_CONFIG_ROOT} = 't';

my $result = test_dzil('corpus/dist/DZ1', [ qw(listdeps --cpanfile) ]);

my $cpanfile = file($result->tempdir, 'source', 'cpanfile');
file_exists_ok($cpanfile, 'Successfully created a cpanfile');
file_contains_like($cpanfile, qr/requires "ExtUtils::MakeMaker"/);

done_testing;
