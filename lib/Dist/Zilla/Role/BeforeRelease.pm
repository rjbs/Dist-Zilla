use strict;
use warnings;

package Dist::Zilla::Role::BeforeRelease;
# ABSTRACT: something that runs before release really begins

use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'before_release';

no Moose::Role;
1;
__END__

=head1 DESCRIPTION

Plugins implementing this role have their C<before_release> method
called before the release is actually done.

=cut
