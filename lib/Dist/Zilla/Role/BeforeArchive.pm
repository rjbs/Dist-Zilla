use strict;
use warnings;

package Dist::Zilla::Role::BeforeArchive;
# ABSTRACT: something that runs before creating the archive begins

use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'before_archive';

no Moose::Role;
1;
__END__

=head1 DESCRIPTION

Plugins implementing this role have their C<before_archive> method
called before the archive is actually built. It is passed a hashref
with the following data:

  build_root - the directory in which the dist was built



=cut
