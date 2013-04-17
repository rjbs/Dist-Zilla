#!perl

use strict;
use warnings;
use Test::More 0.88;
use Test::LongString;

use lib 't/lib';

use autodie;
use Test::DZil;

# test cases are array refs containing
# a case (up to 'EOC') and
# a result (up to 'EOR')
my $cases = [

    # dead simple functionality.
    [   <<'EOC'
package Simple;

1;
EOC
        ,
        <<'EOR'
package Simple;
{
  $Simple::VERSION = '0.001';
}

1;
EOR
    ],

    # should insert after use Moose line
    [   <<'EOC'
package Simple;

use Moose 2.42;

1;
EOC
        ,
        <<'EOR'
package Simple;

use Moose 2.42;
{
  $Simple::VERSION = '0.001';
}

1;
EOR
    ],

    # should insert after use SomethingElse
    [   <<'EOC'
package CommentsEverywhere;  # a comment on the package line
# a comment immediately after the package line

# comment explaining something critical about what is below
use Moose 2.42;  # frobnicator support
use SomethingElse;

# explain something about $var
my $var = 42;

1;
EOC
        ,
        <<'EOR'
package CommentsEverywhere;  # a comment on the package line
# a comment immediately after the package line

# comment explaining something critical about what is below
use Moose 2.42;  # frobnicator support
use SomethingElse;
{
  $CommentsEverywhere::VERSION = '0.001';
}

# explain something about $var
my $var = 42;

1;
EOR
    ],

    # package then space then stmt
    [   <<'EOC'
package Doh; my $x = 42;

1;
EOC
        ,
        <<'EOR'
package Doh; 
{
  $Doh::VERSION = '0.001';
}
my $x = 42;

1;
EOR
    ],

    # package then stmt, no space!
    [   <<'EOC'
package Doh;my $x = 42;

1;
EOC
        ,
        <<'EOR'
package Doh;
{
  $Doh::VERSION = '0.001';
}
my $x = 42;

1;
EOR
    ],

    # should insert before BEGIN containing require
    [   << 'EOC'
package Ape; # meaningful comment here

use Moose 2.0; # frobnicator support
BEGIN {
    unless (\$ENV{$env}) {
        require Test::More;
        Test::More::plan(skip_all => 'these tests are for $msg');
    }
}

1;
EOC
        ,
        <<'EOR'
package Ape; # meaningful comment here

use Moose 2.0; # frobnicator support
{
  $Ape::VERSION = '0.001';
}
BEGIN {
    unless (\$ENV{$env}) {
        require Test::More;
        Test::More::plan(skip_all => 'these tests are for $msg');
    }
}

1;
EOR
    ],

    # should insert before the require
    [   << 'EOC'
package Tarzan; # meaningful comment here

use Moose 2.0; # frobnicator support
require Test::More;

1;
EOC
        ,
        <<'EOR'
package Tarzan; # meaningful comment here

use Moose 2.0; # frobnicator support
{
  $Tarzan::VERSION = '0.001';
}
require Test::More;

1;
EOR
    ],

    # should insert before the 'no' statement
    [   << 'EOC'
package Jane; # meaningful comment here

use Moose 2.0; # frobnicator support
no Poodle;

1;
EOC
        ,
        <<'EOR'
package Jane; # meaningful comment here

use Moose 2.0; # frobnicator support
{
  $Jane::VERSION = '0.001';
}
no Poodle;

1;
EOR
    ],

];


sub dzt_it {
    my $input = shift;

    my $tzil = Builder->from_config(

        # waste, ends up processing DZT/Sample every time....
        { dist_root => 'corpus/dist/DZT' },
        {   add_files => {
                'source/lib/Tmp.pm' => $input,
                'Source/dist.ini' =>
                    simple_ini( 'GatherDir', 'PkgVersion', 'ExecDir' ),
            },
        },
    );
    $tzil->build;
    my $dzt_output = $tzil->slurp_file('build/lib/Tmp.pm');
    return $dzt_output;
}

for my $case ( @{$cases} ) {
    my $result = dzt_it( $case->[0] );
    is_string( $result, $case->[1] );
}

done_testing;

