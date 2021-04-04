package Dist::Zilla::Role::AfterRelease;
# ABSTRACT: something that runs after release is mostly complete

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

Plugins implementing this role have their C<after_release> method called once
the release is done. The archive filename, if one was built, is passed as the
sole argument.

=cut

requires 'after_release';

1;
