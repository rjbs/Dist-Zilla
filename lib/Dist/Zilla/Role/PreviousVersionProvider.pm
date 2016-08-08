package Dist::Zilla::Role::PreviousVersionProvider;
# ABSTRACT: something that provides the dist's previous version number
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

=head1 DESCRIPTION

Plugins implementing this role must provide a C<previous_version> 
method that might be called when another (or the same) plugin implementing
the C<VersionProvider> role will set the dist's version. 

If no previous version exists, the plugin is expected to return C<undef>.

=cut

requires 'previous_version';

no Moose::Role;
1;
