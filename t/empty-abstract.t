use strict;
use warnings;

use Test::More;
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use List::Util 'first';

my $tzil = Builder->from_config(
    { dist_root => 't/does_not_exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'GatherDir',
            ),
            path(qw(source lib DZT Sample.pm)) => <<MODULE,
package DZT::Sample;

# ABSTRACT:

return 1;
__END__

=head1 NAME

DZT::Sample - a sample module for testing handling of empty ABSTRACT comment

=head1 HEY, MAINTAINER

Note that we have C<< =head1 NAME >> here, and an empty ABSTRACT comment.

The empty ABSTRACT comment should be skipped, and the NAME one used.

=cut
MODULE
        },
    },
);

is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

is(
    Dist::Zilla::Util->abstract_from_file(first { $_->name eq 'lib/DZT/Sample.pm' } @{$tzil->files}),
    'a sample module for testing handling of empty ABSTRACT comment',
    'We should see the abstract from the =head NAME section in pod',
);

done_testing;
