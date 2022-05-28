package Dist::Zilla::Role::EncodingProvider;
# ABSTRACT: something that sets a files' encoding

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

=head1 DESCRIPTION

EncodingProvider plugins do their work after files are gathered, but before
they're munged.  They're meant to set the C<encoding> on files.

The method C<set_file_encodings> is called with no arguments.

=cut

requires 'set_file_encodings';

1;
