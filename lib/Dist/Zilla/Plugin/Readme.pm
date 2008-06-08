package Dist::Zilla::Plugin::Readme;
# ABSTRACT: build a README file
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::TextTemplate';

sub gather_files {
  my ($self, $arg) = @_;

  require Dist::Zilla::File::InMemory;

  my $template = q|

This archive contains the distribution {{ $dist->name }}, version
{{ $dist->version }}:

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
