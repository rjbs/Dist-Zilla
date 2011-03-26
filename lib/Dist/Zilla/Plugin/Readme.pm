package Dist::Zilla::Plugin::Readme;
# ABSTRACT: build a README file
use Moose;
use Moose::Autobox;
with qw/Dist::Zilla::Role::FileGatherer Dist::Zilla::Role::TextTemplate/;

=head1 DESCRIPTION

This plugin adds a very simple F<README> file to the distribution, citing the
dist's name, version, abstract, and license.  It may be more useful or
informative in the future.

=cut

sub gather_files {
  my ($self, $arg) = @_;

  require Dist::Zilla::File::InMemory;

  my $template = q|

This archive contains the distribution {{ $dist->name }},
version {{ $dist->version }}:

  {{ $dist->abstract }}

{{ $dist->license->notice }}

|;

  my $content = $self->fill_in_string(
    $template,
    { dist => \($self->zilla) },
  );

  my $file = Dist::Zilla::File::InMemory->new({
    content => $content,
    name    => 'README',
  });

  $self->add_file($file);
  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
