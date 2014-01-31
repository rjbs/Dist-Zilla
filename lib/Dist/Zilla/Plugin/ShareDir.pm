package Dist::Zilla::Plugin::ShareDir;
# ABSTRACT: install a directory's contents as "ShareDir" content

use Moose;
with 'Dist::Zilla::Role::ShareDir';

use namespace::autoclean;

use Moose::Autobox;

=head1 SYNOPSIS

In your F<dist.ini>:

  [ShareDir]
  dir = share

  If no C<dir> is provided, the default is F<share>.

=cut

has dir => (
  is   => 'ro',
  isa  => 'Str',
  default => 'share',
);

around dump_config => sub {
  my $orig = shift;
  my $self = shift;

  my $config = $self->$orig;

  $config->{'' . __PACKAGE__} = { dir => $self->dir };

  return $config;
};


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

__PACKAGE__->meta->make_immutable;
1;
