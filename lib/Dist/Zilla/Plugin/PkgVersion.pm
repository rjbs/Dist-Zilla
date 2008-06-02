package Dist::Zilla::Plugin::PkgVersion;
use Moose;
with 'Dist::Zilla::Role::FileMunger';

sub munge_file {
  my ($self, $file) = @_;

  return $self->munge_perl($file) if $file->name    =~ /\.(?:pm|pl)$/i;
  return $self->munge_perl($file) if $file->content =~ /^#!perl(?:$|\s)/;
  return;
}

sub munge_perl {
  my ($self, $file) = @_;

  my $content = $file->content;

  if ($content =~ /\$VERSION\s*=/) {
    $self->log(sprintf('skipping %s: assigns to $VERSION', $file->name));
    return;
  }

  my $version = $self->zilla->version;
  Carp::croak("invalid characters in version") if $version !~ /\A[.0-9_]+\z/;

  # That \x20 is my OH SO CLEVER way of thwarting the \s* above.
  # -- rjbs, 2008-06-02
  $content =~ s/^(package \S+;)$/$1\nour \$VERSION\x20= '$version';\n/mg;
  $file->content($content);
}

1;
