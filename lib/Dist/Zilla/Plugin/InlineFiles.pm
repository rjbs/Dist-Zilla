package Dist::Zilla::Plugin::InlineFiles;
# ABSTRACT: files in a data section

use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

use namespace::autoclean;

=head1 DESCRIPTION

This plugin exists only to be extended, and gathers all files contained in its
data section and those of its ancestors.  For more information, see
L<Data::Section|Data::Section>.

=cut

use Sub::Exporter::ForMethods;
use Data::Section 0.200002 # encoding and bytes
  { installer => Sub::Exporter::ForMethods::method_installer },
  '-setup' => { encoding => 'bytes' };
use Dist::Zilla::File::InMemory;

sub gather_files {
  my ($self) = @_;

  my $data = $self->merged_section_data;
  return unless $data and %$data;

  for my $name (keys %$data) {
    $self->add_file(
      Dist::Zilla::File::InMemory->new({
        name    => $name,
        content => ${ $data->{$name} },
      }),
    );
  }

  return;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 SEE ALSO

Core Dist::Zilla plugins inheriting from L<InlineFiles>:
L<MetaTests|Dist::Zilla::Plugin::MetaTests>,
L<PodCoverageTests|Dist::Zilla::Plugin::PodCoverageTests>,
L<PodSyntaxTests|Dist::Zilla::Plugin::PodSyntaxTests>.

=cut
