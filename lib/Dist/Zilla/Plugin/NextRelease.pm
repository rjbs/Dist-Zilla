package Dist::Zilla::Plugin::NextRelease;
# ABSTRACT: update the next release number in your changelog
use Moose;
with 'Dist::Zilla::Role::FileMunger';
with 'Dist::Zilla::Role::TextTemplate';
with 'Dist::Zilla::Role::AfterRelease';

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
  my $now = DateTime->from_epoch(epoch => $^T);

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

sub after_release {
  my ($self) = @_;

  my $filename = $self->filename;

  my $content = do {
    local $/;
    open my $in_fh, '<', $filename
      or Carp::croak("can't open $filename for reading: $!");
    <$in_fh>
  };

  my $delim  = $self->delim;
  my $header = $self->section_header;

  $content =~ s{ (\Q$delim->[0]\E \s*) \$NEXT (\s* \Q$delim->[1]\E) }
               {$1\$NEXT$2\n\n$header}xs;

  open my $out_fh, '>', $filename
    or Carp::croak("can't open $filename for writing: $!");

  print $out_fh $content or Carp::croak("error writing to $filename: $!");
  close $out_fh or Carp::croak("error closing $filename: $!");
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
