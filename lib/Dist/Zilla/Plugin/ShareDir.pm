package Dist::Zilla::Plugin::ShareDir;
# ABSTRACT: install a directory's contents as "ShareDir" content
use Moose;

use Moose::Autobox;

=head1 SYNOPSIS

In your F<dist.ini>:

  [ShareDir]

=cut

has dir => (
  is   => 'ro',
  isa  => 'Str',
  default => 'share',
);

sub find_files {
  my ($self) = @_;

  my $dir = $self->dir;
  my $files = $self->zilla->files->grep(sub { index($_->name, "$dir/") == 0 });
}

sub share_dir_map {
  my ($self) = @_;
  my $files = $self->find_files;
  return unless @$files;

  return { dist => $self->dir };
}

with 'Dist::Zilla::Role::ShareDir';
__PACKAGE__->meta->make_immutable;
no Moose;
1;
