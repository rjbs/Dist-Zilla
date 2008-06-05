package Dist::Zilla::Plugin::Readme;
# ABSTRACT: build a README file
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileWriter';
with 'Dist::Zilla::Role::TextTemplate';

sub write_files {
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

  return [ $file ];
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
