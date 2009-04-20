package Dist::Zilla::Role::MetaProvider;
# ABSTRACT: something that provides metadata (for META.yml/json)
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

=head1 DESCRIPTION

This role provides data to merge into the distribution metadata.

=method metadata

This method returns a hashref of data to be (deeply) merged together with
pre-existing metadata.

=cut

requires 'metadata';

no Moose::Role;
1;
