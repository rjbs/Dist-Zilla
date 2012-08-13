use strict;
use warnings;
use lib 't/lib';

use Test::More 0.88;
use Test::DZil qw(Builder simple_ini);
use Test::Exception;

my $ROOT;

BEGIN {
    $ROOT = 'corpus/dist/DZ-FVT';

    require lib;
    lib->import("$ROOT/lib");
}

plan tests => 2;

{
    lives_ok {
        my $tzil = Builder->from_config(
            { dist_root => $ROOT },
            {
                add_files => {
                    'source/dist.ini' => simple_ini(
                        [ '@Filter' => {
                            '-bundle'  => '@FilterVersionTest',
                            '-version' => '0.01',
                            # XXX what does :version even refer to?
                        } ]
                    ),
                },
            },
        );

        $tzil->release;
    };
}

{
    throws_ok {
        my $tzil = Builder->from_config(
            { dist_root => $ROOT },
            {
                add_files => {
                    'source/dist.ini' => simple_ini(
                        [ '@Filter' => {
                            '-bundle'     => '@FilterVersionTest',
                            '-version' => '0.02',
                        } ]
                    ),
                },
            },
        );

        $tzil->release;
    } qr/\QDist::Zilla::PluginBundle::FilterVersionTest version 0.02 required--this is only version 0.01\E/;
}
