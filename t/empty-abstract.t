#! perl

use strict;
use warnings;
use Dist::Zilla::Util;
use Dist::Zilla::File::OnDisk;
use Test::More 0.88;

my $file = Dist::Zilla::File::OnDisk->new({name => 'corpus/dist/DZ3/lib/DZ3.pm'})
            || BAIL_OUT("can't find DZ3.pm");

my $expected = 'a sample module for testing handling of empty ABSTRACT comment';
my $abstract = Dist::Zilla::Util->abstract_from_file($file);

is($abstract, $expected, "We should see the abstract from the =head NAME section in pod");

done_testing();
