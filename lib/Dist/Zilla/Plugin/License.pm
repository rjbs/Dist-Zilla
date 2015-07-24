package Dist::Zilla::Plugin::License;
# ABSTRACT: output a LICENSE file

use Moose;
with 'Dist::Zilla::Role::FileGatherer';

use namespace::autoclean;

=head1 DESCRIPTION

This plugin adds a F<LICENSE> file containing the full text of the
distribution's license, as produced by the C<fulltext> method of the
dist's L<Software::License> object.

=attr filename

This attribute can be used to specify a name other than F<LICENSE> to be used.

=cut

use Dist::Zilla::File::InMemory;

has filename => (
  is  => 'ro',
  isa => 'Str',
  default => 'LICENSE',
);

sub gather_files {
  my ($self, $arg) = @_;

  my $file = Dist::Zilla::File::InMemory->new({
    name    => $self->filename,
    content => $self->zilla->license->fulltext,
  });

  $self->add_file($file);
  return;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 SEE ALSO

=over 4

=item *

the C<license> attribute of the L<Dist::Zilla> object to select the license
to use.

=item *

Dist::Zilla roles:
L<FileGatherer|Dist::Zilla::Role::FileGatherer>.

=item *

Other modules:
L<Software::License>,
L<Software::License::Artistic_2_0>.

=back

=cut
