package Dist::Zilla::Plugin::Prereq;
# ABSTRACT: (DEPRECATED) the old name of the Prereqs plugin
use Moose;
extends 'Dist::Zilla::Plugin::Prereqs';

=head1 SYNOPSIS

This plugin extends C<[Prereqs]> and adds nothing.  It is the old name for
Prereqs, and will be removed in a few versions.

=cut

before register_component => sub {
  die "[Prereq] is incompatible with Dist::Zilla >= v5; replace it with [Prereqs] (note the
  's')"
    if Dist::Zilla->VERSION >= 5;
  warn "!!! [Prereq] will be removed in Dist::Zilla v5; replace it with [Prereqs] (note the 's')\n";
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
