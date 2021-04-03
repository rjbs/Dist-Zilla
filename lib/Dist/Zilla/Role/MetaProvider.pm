package Dist::Zilla::Role::MetaProvider;
# ABSTRACT: something that provides metadata (for META.yml/json)

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

This role provides data to merge into the distribution metadata.

=method metadata

This method (which must be provided by classes implementing this role)
returns a hashref of data to be (deeply) merged together with pre-existing
metadata.

=cut

requires 'metadata';

1;
__END__

=head1 SEE ALSO

Core Dist::Zilla plugins implementing this role:
L<ConfigMeta|Dist::Zilla::Plugin::ConfigMeta>.
L<MetaNoIndex|Dist::Zilla::Plugin::MetaNoIndex>.

Dist::Zilla plugins on the CPAN:
L<GithubMeta|Dist::Zilla::Plugin::GithubMeta>...

=cut
