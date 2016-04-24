use strict;
use warnings;

use Test::More 0.88;
use Dist::Zilla::Tester;
use Test::DZil;
use Test::Fatal;

my $tzil;
is(
  exception {
    $tzil = Builder->from_config(
      { dist_root => 'does-not-exist' },
      {
        add_files => {
          'source/dist.ini' => simple_ini(
            [ GatherDir => ],
            [ MetaJSON => ],
            [ '=inc::MyMetadata' ],
          ),
          'source/inc/MyMetadata.pm' => <<PLUGIN
package inc::MyMetadata;
use Moose;
with 'Dist::Zilla::Role::MetaProvider';
sub metadata { +{} }
1;
PLUGIN
        },
      },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;
  },
  undef,
  q{config does not blow up with "Required plugin inc::MyMetadata isn't installed."},
);

done_testing;
