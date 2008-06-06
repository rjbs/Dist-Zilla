package Dist::Zilla::Plugin::NextRelease;
# ABSTRACT: update the next release number in your changelog
use Moose;
with 'Dist::Zilla::Role::FileMunger';
with 'Dist::Zilla::Role::TextTemplate';

has format => (
  is  => 'ro',
  isa => 'Str', # should be more validated Later -- rjbs, 2008-06-05
  default => '%-9v %{yyyy-MM-dd HH:mm:ss VVVV}d',
);

has filename => (
  is  => 'ro',
  isa => 'Str',
  default => 'Changes',
);

sub section_header {
  my ($self) = @_;

  require String::Format;
  my $string = $self->format;

  # XXX: if possible, get the time zone from Wherever -- rjbs, 2008-06-05
  require DateTime;
  my $now = DateTime->now;

  String::Format::stringf(
    $string,
    (
      v => $self->zilla->version,
      d => sub { $now->format_cldr($_[0]) }, 
    ),
  );
}

sub munge_file {
  my ($self, $file) = @_;

  return unless $file->name eq $self->filename;

  my $content = $self->fill_in_string(
    $file->content,
    {
      dist    => \($self->zilla),
      version => \($self->zilla->version),
      NEXT    => \($self->section_header),
    },
  );

  $file->content($content);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
