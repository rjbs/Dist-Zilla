use strict;
use warnings;
use Test::More 0.88;

use autodie;
use utf8;
use Test::DZil;
use Try::Tiny;

my $missing_blank_re = qr/^\[PkgVersion\] no blank line for \$VERSION after /;

# test cases are hash refs containing:
# input => the input to a test case
# skip_over_output => the expeced result when skip_over_use_statements => 1
# default_output => the expeced result when skip_over_use_statements => 0
# missing_blank_message => a regexp to match against exception thrown
#    die_on_line_insertion => 1 and the case is expected to blow up.
#
my $cases = [

    ################################################################
    # test the simple functionality.
    {   input => <<'EO_INPUT'
package Simple;

1;
EO_INPUT
        ,
        skip_over_output => <<'EO_EXPECTED'
package Simple;
$Simple::VERSION = '0.001';
1;
EO_EXPECTED
        ,
        default_output => <<'EO_EXPECTED'
package Simple;
$Simple::VERSION = '0.001';
1;
EO_EXPECTED
    },

    ################################################################
    # When run with die_on_line_insertion below, this should die with a
    # complaint about lack of a blank line after package statement.
    {   input => <<'EO_INPUT'
package Simple;
1;
EO_INPUT
        ,
        missing_blank_message => $missing_blank_re,
        skip_over_output      => <<'EO_EXPECTED'
package Simple;
$Simple::VERSION = '0.001';
1;
EO_EXPECTED
        ,
        default_output => <<'EO_EXPECTED'
package Simple;
$Simple::VERSION = '0.001';
1;
EO_EXPECTED
    },

    ################################################################
    # This should insert after the 'use Moose' line when skipping, after package
    # otherwise.
    {   input => <<'EO_INPUT'
package Simple;
use Moose 2.42;

1;
EO_INPUT
        ,
        skip_over_output => <<'EO_EXPECTED'
package Simple;
use Moose 2.42;
$Simple::VERSION = '0.001';
1;
EO_EXPECTED
        ,
        default_output => <<'EO_EXPECTED'
package Simple;
$Simple::VERSION = '0.001';
use Moose 2.42;

1;
EO_EXPECTED
    },

    ################################################################
    # When run with die_on_line_insertion => 1, this should die. Otherwise it
    # should insert after 'use Moose' when skipping and 'package' when not.
    {   input => <<'EO_INPUT'
package Simple;
use Moose 2.42;
1;
EO_INPUT
        ,
        missing_blank_message => $missing_blank_re,
        skip_over_output      => <<'EO_INPUT'
package Simple;
use Moose 2.42;
$Simple::VERSION = '0.001';
1;
EO_INPUT
        ,
        default_output => <<'EO_INPUT'
package Simple;
$Simple::VERSION = '0.001';
use Moose 2.42;
1;
EO_INPUT

    },

    ################################################################
    # When skipping, should insert after 'use SomethingElse', otherwise should
    # insert after 'package'.
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
        skip_over_output => <<'EO_EXPECTED'
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
        ,
        default_output => <<'EO_EXPECTED'
package CommentsEverywhere;  # a comment on the package line
$CommentsEverywhere::VERSION = '0.001';
# a comment immediately after the package line
# comment explaining something critical about what is below
use Moose 2.42;  # frobnicator support
use SomethingElse;

# explain something about $var
my $var = 42;
1;
EO_EXPECTED
    },

    ################################################################
    # When die_on...=> 1, should die. Otherwise, when skipping should insert
    # after 'use SomethingElse', when not skipping should insert after
    # 'package'.
    #
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
        skip_over_output      => <<'EO_EXPECTED'
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
        ,
        default_output => <<'EO_EXPECTED'
package CommentsEverywhere;  # a comment on the package line
$CommentsEverywhere::VERSION = '0.001';
# a comment immediately after the package line
# comment explaining something critical about what is below
use Moose 2.42;  # frobnicator support
use SomethingElse;
# explain something about $var
my $var = 42;
1;
EO_EXPECTED
    },

    ################################################################
    # When die_on... => 1 should die.  Otherwise insert on 'package' line
    {   input => <<'EO_INPUT'
package Doh;my $x = 42;
1;
EO_INPUT
        ,
        missing_blank_message => $missing_blank_re,
        skip_over_output      => <<'EO_EXPECTED'
package Doh;$Doh::VERSION = '0.001';
my $x = 42;
1;
EO_EXPECTED
        ,
        default_output => <<'EO_EXPECTED'
package Doh;$Doh::VERSION = '0.001';
my $x = 42;
1;
EO_EXPECTED
    },

    ################################################################
    # When skipping, should insert after 'use Moose'. Otherwise should insert
    # after 'package'
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
        skip_over_output => <<'EO_EXPECTED'
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
        ,
        default_output => <<'EO_EXPECTED'
package Ape; # meaningful comment here
$Ape::VERSION = '0.001';
use Moose 2.0; # frobnicator support

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
    # When die_on...=> 1, should die, otherwise insert after 'use Moose' when
    # skipping and after 'package' when not.
    # containing require
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
        skip_over_output      => <<'EO_EXPECTED'
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
        ,
        default_output => <<'EO_EXPECTED'
package Ape; # meaningful comment here
$Ape::VERSION = '0.001';
use Moose 2.0; # frobnicator support
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
    # When skipping, should insert before 'require'.  Otherwise should insert
    # after 'package'.
    {   input => << 'EO_INPUT'
package Tarzan; # meaningful comment here
use Moose 2.0; # frobnicator support

require Test::More;
1;
EO_INPUT
        ,
        skip_over_output => <<'EO_EXPECTED'
package Tarzan; # meaningful comment here
use Moose 2.0; # frobnicator support
$Tarzan::VERSION = '0.001';
require Test::More;
1;
EO_EXPECTED
        ,
        default_output => <<'EO_EXPECTED'
package Tarzan; # meaningful comment here
$Tarzan::VERSION = '0.001';
use Moose 2.0; # frobnicator support

require Test::More;
1;
EO_EXPECTED
    },

    ################################################################
    # when die_on...=> 1, should die, otherwise should insert before the
    # require when skipping and after package when not.
    {   input => << 'EO_INPUT'
package Tarzan; # meaningful comment here
use Moose 2.0; # frobnicator support
require Test::More;
1;
EO_INPUT
        ,
        missing_blank_message => $missing_blank_re,
        skip_over_output      => <<'EO_EXPECTED'
package Tarzan; # meaningful comment here
use Moose 2.0; # frobnicator support
$Tarzan::VERSION = '0.001';
require Test::More;
1;
EO_EXPECTED
        ,
        default_output => <<'EO_EXPECTED'
package Tarzan; # meaningful comment here
$Tarzan::VERSION = '0.001';
use Moose 2.0; # frobnicator support
require Test::More;
1;
EO_EXPECTED
    },

    ################################################################
    # should insert before the 'no' statement when skipping, after 'package'
    # otherwise.
    {   input => << 'EO_INPUT'
package Jane; # meaningful comment here
use Moose 2.0; # frobnicator support

no Poodle;
1;
EO_INPUT
        ,
        skip_over_output => <<'EO_EXPECTED'
package Jane; # meaningful comment here
use Moose 2.0; # frobnicator support
$Jane::VERSION = '0.001';
no Poodle;
1;
EO_EXPECTED
        ,
        default_output => <<'EO_EXPECTED'
package Jane; # meaningful comment here
$Jane::VERSION = '0.001';
use Moose 2.0; # frobnicator support

no Poodle;
1;
EO_EXPECTED
    },

    ################################################################
    # when die_on...=> 1, should die, otherwise should insert before the 'no'
    # statement when skipping and after 'package' otherwise.
    {   input => << 'EO_INPUT'
package Jane; # meaningful comment here
use Moose 2.0; # frobnicator support
no Poodle;
1;
EO_INPUT
        ,
        missing_blank_message => $missing_blank_re,
        skip_over_output      => <<'EO_EXPECTED'
package Jane; # meaningful comment here
use Moose 2.0; # frobnicator support
$Jane::VERSION = '0.001';
no Poodle;
1;
EO_EXPECTED
        ,
        default_output => <<'EO_EXPECTED'
package Jane; # meaningful comment here
$Jane::VERSION = '0.001';
use Moose 2.0; # frobnicator support
no Poodle;
1;
EO_EXPECTED
    },

];

diag("die => 0, skip => 0");
for my $case ( @{$cases} ) {
    my $result = dzt_it(
        {   input                    => $case->{input},
            die_on_line_insertion    => 0,
            skip_over_use_statements => 0,
        }
    );
    is( $result->{output}, $case->{default_output} );
}

diag("die => 0, skip => 1");
for my $case ( @{$cases} ) {
    my $result = dzt_it(
        {   input                    => $case->{input},
            die_on_line_insertion    => 0,
            skip_over_use_statements => 1,
        }
    );
    is( $result->{output}, $case->{skip_over_output} );
}

diag("die => 1, skip => 1");
for my $case ( @{$cases} ) {
    my $result = dzt_it(
        {   input                    => $case->{input},
            die_on_line_insertion    => 1,
            skip_over_use_statements => 1,
        }
    );
    if ( $case->{missing_blank_message} ) {
        like( $result->{error}, $case->{missing_blank_message} );
    }
    else {
        is( $result->{output}, $case->{skip_over_output} );
    }
}

sub dzt_it {
    my ($args) = @_;

    my $tzil = Builder->from_config(

        # waste, ends up processing DZT/Sample every time....
        { dist_root => 'corpus/dist/DZT' },
        {   add_files => {
                'source/lib/Tmp.pm' => $args->{input},
                'source/dist.ini'   => simple_ini(
                    'GatherDir',
                    [   'PkgVersion' => {
                            'die_on_line_insertion' =>
                              $args->{die_on_line_insertion},
                            'skip_over_use_statements' =>
                              $args->{skip_over_use_statements},
                        }
                    ],
                    'ExecDir'
                ),
            },
        },
    );
    my ( $error, $output );
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
