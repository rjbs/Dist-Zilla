package Dist::Zilla::Plugin::ExecDir;
# ABSTRACT: install a directory's contents as executables

use Moose;

use namespace::autoclean;

use Moose::Autobox;

=head1 SYNOPSIS

In your F<dist.ini>:

  [ExecDir]
  dir = scripts

If no C<dir> is provided, the default is F<bin>.

=cut

has dir => (
  is   => 'ro',
  isa  => 'Str',
  default => 'bin',
);

with 'Dist::Zilla::Role::ExecFiles';

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

__PACKAGE__->meta->make_immutable;
1;
