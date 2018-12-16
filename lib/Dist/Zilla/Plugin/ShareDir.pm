package Dist::Zilla::Plugin::ShareDir;
# ABSTRACT: install a directory's contents as "ShareDir" content

use Moose;

use Dist::Zilla::Dialect;

use namespace::autoclean;

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

sub find_files ($self) {
  my $dir = $self->dir;
  return [ grep { index($_->name, "$dir/") == 0 } $self->zilla->files->@* ];
}

sub share_dir_map ($self) {
  my $files = $self->find_files;
  return unless @$files;

  return { dist => $self->dir };
}

with 'Dist::Zilla::Role::ShareDir';

around dump_config => sub {
  my $orig = shift;
  my $self = shift;

  my $config = $self->$orig;

  $config->{+__PACKAGE__} = { dir => $self->dir };

  return $config;
};

__PACKAGE__->meta->make_immutable;
1;
