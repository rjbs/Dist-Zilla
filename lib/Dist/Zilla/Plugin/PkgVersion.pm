package Dist::Zilla::Plugin::PkgVersion;
use Moose;
with 'Dist::Zilla::Role::FileMunger';

sub munge_file {
  my ($self, $file) = @_;

  return $self->munge_perl($file) if $file->name        =~ /\.(?:pm|pl)$/i;
  return $self->munge_perl($file) if $file->content_ref =~ /^#!perl(?:$|\s)/;
  return;
}

sub munge_content {
  my ($self, $file) = @_;

  my $content = $file->content;

  if ($content =~ /\$VERSION\b/) {
    $self->log(sprintf('skipping %s: already has $VERSION', $file->name));
    return;
  }

  my $version = quotemeta($self->zilla->version);
  $content =~ s/^(package \S+;)$/$1\nour \$VERSION = "$version";\n/smg;
  $file->content($content);
}

1;
