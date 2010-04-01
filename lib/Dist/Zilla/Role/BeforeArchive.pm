package Dist::Zilla::Role::BeforeArchive;
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';
# ABSTRACT: something that runs before the archive file is built

requires 'before_archive';

no Moose::Role;
1;
__END__

=head1 DESCRIPTION

Plugins implementing this role have their C<before_archive> method
called before the archive is actually built.

=cut
