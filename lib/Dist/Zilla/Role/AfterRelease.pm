use strict;
use warnings;

package Dist::Zilla::Role::AfterRelease;
# ABSTRACT: something that runs after release is mostly complete

use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'after_release';

no Moose::Role;
1;
__END__

=head1 DESCRIPTION

Plugins implementing this role have their C<after_release> method called
once the release is done.

=cut
