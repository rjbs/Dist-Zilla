package Dist::Zilla::Plugin::Prereq;
# ABSTRACT: DEPRECATED: the old name of the Prereqs plugin
use Moose;
extends 'Dist::Zilla::Plugin::Prereqs';

=head1 SYNOPSIS

This plugin extends C<[Prereqs]> and adds nothing.  It is the old name for
Prereqs, and will be removed in a few versions.

=cut

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
