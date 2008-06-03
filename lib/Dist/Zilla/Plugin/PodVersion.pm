package Dist::Zilla::Plugin::PodVersion;
use Moose;
with 'Dist::Zilla::Role::FileMunger';

sub munge_file {
  my ($self, $file) = @_;

  return $self->munge_pod($file)
    if $file->name =~ /\.pm$/i and $file->name !~ m{^t/};

  return unless $file->content =~ /^#!perl(?:$|\s)/;

  return if $file->name eq 'Makefile.PL';
  return if $file->name eq 'Build.PL';
  return if $file->name =~ /\.t$/;

  return $self->munge_pod($file);
}

sub munge_pod {
  my ($self, $file) = @_;

  my @content = split /\n/, $file->content;
  
  if (grep { /^=head1 VERSION\b/ } @content) {
    $self->log($file->name . ' already has a VERSION section in POD');
    return;
  }

  for (0 .. $#content) {
    next until $content[$_] =~ /^=head1 NAME/;

    $_++; # move past the =head1 line itself
    $_++ while $content[$_] =~ /^\s*$/;

    $_++; # move past the line with the abstract
    $_++ while $content[$_] =~ /^\s*$/;

    splice @content, $_ - 1, 0, (
      "",
      "=head1 VERSION",
      "",
      "version " . $self->zilla->version . "",
    );

    $file->content(join "\n", @content);
    return;
  }

  $self->log(
    "couldn't find a place to insert VERSION section to "
    . $file->name,
  );
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
