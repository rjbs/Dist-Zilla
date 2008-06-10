package Dist::Zilla::Plugin::License;
# ABSTRACT: output a LICENSE file
use Moose;
with 'Dist::Zilla::Role::FileGatherer';

=head1 DESCRIPTION

This plugin adds a F<LICENSE> file containing the full text of the
distribution's license, as produced by the C<fulltext> method of the
dist's L<Software::License> object.

=cut

use Dist::Zilla::File::InMemory;

sub gather_files {
  my ($self, $arg) = @_;

  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'LICENSE',
    content => $self->zilla->license->fulltext,
  });

  $self->add_file($file);
  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
