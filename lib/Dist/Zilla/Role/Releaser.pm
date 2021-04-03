package Dist::Zilla::Role::Releaser;
# ABSTRACT: something that makes a release of the dist

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

=head1 DESCRIPTION

Plugins implementing this role have their C<release> method called when
releasing.  It's passed the distribution tarball to be released.

=cut

requires 'release';

1;
