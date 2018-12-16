package Dist::Zilla::Plugin::ExecDir;
# ABSTRACT: install a directory's contents as executables

use Moose;

use Dist::Zilla::Dialect;

use namespace::autoclean;

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

  $config->{+__PACKAGE__} = { dir => $self->dir };

  return $config;
};

__PACKAGE__->meta->make_immutable;
1;
