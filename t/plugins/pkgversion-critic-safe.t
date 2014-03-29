#!perl

use strict;
use warnings;
use Test::More 0.88;
use Test::LongString;

use lib 't/lib';

use autodie;
use Test::DZil;
use Try::Tiny;

my $missing_blank_re = qr/^\[PkgVersion\] no blank line for \$VERSION after /;

# test cases are array refs containing
# a case (up to 'EO_INPUT') and
# a result (up to 'EO_EXPECTED')
my $cases = [

    ################################################################
    # test the simple functionality.
    {   input => <<'EO_INPUT'
package Simple;

1;
EO_INPUT
        ,
        output => <<'EO_EXPECTED'
package Simple;
$Simple::VERSION = '0.001';
1;
EO_EXPECTED
    },

    ################################################################
    # given that we run with die_on_line_insertion below, this should die with
    # a complaint about lack of a blank line after package statement.
    {   input => <<'EO_INPUT'
package Simple;
1;
EO_INPUT
        ,
        missing_blank_message => $missing_blank_re,
        output                => <<'EO_EXPECTED'
package Simple;
$Simple::VERSION = '0.001';
1;
EO_EXPECTED
    },

    ################################################################
    # should insert after use Moose line
    {   input => <<'EO_INPUT'
package Simple;

use Moose 2.42;

1;
EO_INPUT
        ,
        output => <<'EO_EXPECTED'
package Simple;

use Moose 2.42;
$Simple::VERSION = '0.001';
1;
EO_EXPECTED
    },

    ################################################################
    # given that we run with die_on_line_insertion below, this should die with
    # a complaint about lack of a blank line after where it want's to do the
    # insert (after use Moose).
    {   input => <<'EO_INPUT'
package Simple;

use Moose 2.42;
1;
EO_INPUT
        ,
        missing_blank_message => $missing_blank_re,
        output                => <<'EO_INPUT'
package Simple;

use Moose 2.42;
$Simple::VERSION = '0.001';
1;
EO_INPUT

    },

    ################################################################
    # should insert after use SomethingElse
    {   input => <<'EO_INPUT'
package CommentsEverywhere;  # a comment on the package line
# a comment immediately after the package line

# comment explaining something critical about what is below
use Moose 2.42;  # frobnicator support
use SomethingElse;

# explain something about $var
my $var = 42;

1;
EO_INPUT
        ,
        output => <<'EO_EXPECTED'
package CommentsEverywhere;  # a comment on the package line
# a comment immediately after the package line

# comment explaining something critical about what is below
use Moose 2.42;  # frobnicator support
use SomethingElse;
$CommentsEverywhere::VERSION = '0.001';
# explain something about $var
my $var = 42;

1;
EO_EXPECTED
    },

    ################################################################
    # might die given missing blank line, otherwise
    # should insert after use SomethingElse
    {   input => <<'EO_INPUT'
package CommentsEverywhere;  # a comment on the package line
# a comment immediately after the package line

# comment explaining something critical about what is below
use Moose 2.42;  # frobnicator support
use SomethingElse;
# explain something about $var
my $var = 42;

1;
EO_INPUT
        ,
        missing_blank_message => $missing_blank_re,
        output                => <<'EO_EXPECTED'
package CommentsEverywhere;  # a comment on the package line
# a comment immediately after the package line

# comment explaining something critical about what is below
use Moose 2.42;  # frobnicator support
use SomethingElse;
$CommentsEverywhere::VERSION = '0.001';
# explain something about $var
my $var = 42;

1;
EO_EXPECTED
    },

    ################################################################
    # package then space then stmt
    {   input => <<'EO_INPUT'
package Doh; my $x = 42;

1;
EO_INPUT
        ,
        missing_blank_message => $missing_blank_re,
        output                => <<'EO_EXPECTED'
package Doh; $Doh::VERSION = '0.001';
my $x = 42;

1;
EO_EXPECTED
    },

    ################################################################
    # package then stmt, no space!
    {   input => <<'EO_INPUT'
package Doh;my $x = 42;

1;
EO_INPUT
        ,
        missing_blank_message => $missing_blank_re,
        output                => <<'EO_EXPECTED'
package Doh;$Doh::VERSION = '0.001';
my $x = 42;

1;
EO_EXPECTED
    },

    ################################################################
    # should insert before BEGIN containing require
    {   input => << 'EO_INPUT'
package Ape; # meaningful comment here

use Moose 2.0; # frobnicator support

BEGIN {
    unless (\$ENV{$env}) {
        require Test::More;
        Test::More::plan(skip_all => 'these tests are for $msg');
    }
}

1;
EO_INPUT
        ,
        output => <<'EO_EXPECTED'
package Ape; # meaningful comment here

use Moose 2.0; # frobnicator support
$Ape::VERSION = '0.001';
BEGIN {
    unless (\$ENV{$env}) {
        require Test::More;
        Test::More::plan(skip_all => 'these tests are for $msg');
    }
}

1;
EO_EXPECTED
    },

    ################################################################
    # might die given missing blank line, otherwise
    # should insert before BEGIN containing require
    {   input => << 'EO_INPUT'
package Ape; # meaningful comment here

use Moose 2.0; # frobnicator support
BEGIN {
    unless (\$ENV{$env}) {
        require Test::More;
        Test::More::plan(skip_all => 'these tests are for $msg');
    }
}

1;
EO_INPUT
        ,
        missing_blank_message => $missing_blank_re,
        output                => <<'EO_EXPECTED'
package Ape; # meaningful comment here

use Moose 2.0; # frobnicator support
$Ape::VERSION = '0.001';
BEGIN {
    unless (\$ENV{$env}) {
        require Test::More;
        Test::More::plan(skip_all => 'these tests are for $msg');
    }
}

1;
EO_EXPECTED
    },

    ################################################################
    # should insert before the require
    {   input => << 'EO_INPUT'
package Tarzan; # meaningful comment here

use Moose 2.0; # frobnicator support

require Test::More;

1;
EO_INPUT
        ,
        output => <<'EO_EXPECTED'
package Tarzan; # meaningful comment here

use Moose 2.0; # frobnicator support
$Tarzan::VERSION = '0.001';
require Test::More;

1;
EO_EXPECTED
    },

    ################################################################
    # might die given missing blank line, otherwise
    # should insert before the require
    {   input => << 'EO_INPUT'
package Tarzan; # meaningful comment here

use Moose 2.0; # frobnicator support
require Test::More;

1;
EO_INPUT
        ,
        missing_blank_message => $missing_blank_re,
        output                => <<'EO_EXPECTED'
package Tarzan; # meaningful comment here

use Moose 2.0; # frobnicator support
$Tarzan::VERSION = '0.001';
require Test::More;

1;
EO_EXPECTED
    },

    ################################################################
    # should insert before the 'no' statement
    {   input => << 'EO_INPUT'
package Jane; # meaningful comment here

use Moose 2.0; # frobnicator support

no Poodle;

1;
EO_INPUT
        ,
        output => <<'EO_EXPECTED'
package Jane; # meaningful comment here

use Moose 2.0; # frobnicator support
$Jane::VERSION = '0.001';
no Poodle;

1;
EO_EXPECTED
    },

    ################################################################
    # might die given missing blank line, otherwise
    # should insert before the 'no' statement
    {   input => << 'EO_INPUT'
package Jane; # meaningful comment here

use Moose 2.0; # frobnicator support
no Poodle;

1;
EO_INPUT
        ,
        missing_blank_message => $missing_blank_re,
        output                => <<'EO_EXPECTED'
package Jane; # meaningful comment here

use Moose 2.0; # frobnicator support
$Jane::VERSION = '0.001';
no Poodle;

1;
EO_EXPECTED
    },

];

for my $case ( @{$cases} ) {
    my $result = dzt_it( $case->{input}, 0 );
    is_string( $result->{output}, $case->{output} );

    $result = dzt_it( $case->{input}, 1 );
    if ( $case->{missing_blank_message} ) {
        like_string( $result->{error}, $case->{missing_blank_message} );
    }
    else {
        is_string( $result->{output}, $case->{output} );
    }
}

sub dzt_it {
    my ( $input, $die_on_line_insertion ) = @_;

    my $tzil = Builder->from_config(

        # waste, ends up processing DZT/Sample every time....
        { dist_root => 'corpus/dist/DZT' },
        {   add_files => {
                'source/lib/Tmp.pm' => $input,
                'Source/dist.ini'   => simple_ini(
                    'GatherDir',
                    [   'PkgVersion' => {
                            'die_on_line_insertion' => $die_on_line_insertion,
                        }
                    ],
                    'ExecDir'
                ),
            },
        },
    );
    my $error;
    my $output;
    try {
        $tzil->build;
        $output = $tzil->slurp_file('build/lib/Tmp.pm');
    }
    catch {
        $error = $_;
    };
    my $result = {
        output => $output,
        error  => $error,
    };
    return $result;
}

done_testing;

