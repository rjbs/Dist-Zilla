use strict;
use warnings;

package Dist::Zilla::Role::BuildRunner;
# ABSTRACT: something used as a delegating agent during 'dzil run'

use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'test';

no Moose::Role;
1;
__END__

=head1 DESCRIPTION

Plugins implementing this role have their C<build> method called during
C<dzil run>. It's passed the root directory of the build test dir.


=head1  REQUIRED METHODS

=head2 build()

This method should return C<undef> on success. Any other value is
interpreted as an error message.

Calling "die" inside build also will be caught.

The following 2 subs should behave(mostly) the same:

    sub build {
        die "Failed";
    }

    sub build {
        return "Failed";
    }
