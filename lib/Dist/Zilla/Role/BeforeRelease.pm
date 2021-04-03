package Dist::Zilla::Role::BeforeRelease;
# ABSTRACT: something that runs before release really begins

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

Plugins implementing this role have their C<before_release> method
called before the release is actually done.

=cut

requires 'before_release';

1;
