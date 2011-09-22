use strict;
use warnings;

use Archive::Tar;
use Test::More 0.88;
use Test::DZil;

my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT_zero' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(
                { name => 'DZT_zero', },
                'GatherDir',
                'FakeRelease',
            ),
        },
    },
);

$tzil->release;

my $basename = join( q{}, $tzil->name, '-', $tzil->version, ( $tzil->is_trial ? '-TRIAL' : () ), );

my $tarball = "$basename.tar.gz";

$tarball = $tzil->built_in->parent->subdir( 'source' )->file( $tarball );
$tarball = Archive::Tar->new( $tarball->stringify );

my $zero_byte = File::Spec::Unix->catfile( $basename, 'zero' );

my ( $zero_byte_file ) = $tarball->get_files( $zero_byte );

is( $zero_byte_file->get_content, "", "zero byte file is empty" );

done_testing;
