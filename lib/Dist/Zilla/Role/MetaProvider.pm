package Dist::Zilla::Role::MetaProvider;
# ABSTRACT: something that provides metadata (for META.yml/json)
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;

=head1 DESCRIPTION

This role provides data to merge into the distribution metadata.

=method metadata

This method (which must be provided by classes implementing this role)
returns a hashref of data to be (deeply) merged together with pre-existing
metadata.

=cut

requires 'metadata';

1;
