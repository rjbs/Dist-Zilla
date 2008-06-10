package Dist::Zilla::Plugin::PruneFiles;
# ABSTRACT: prune arbirary files from the dist
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FilePruner';

=head1 SYNOPSIS

This plugin allows you to specify filenames to explicitly prune from your
distribution.  This is useful if another plugin (maybe a FileGatherer) adds a
bunch of files, and you only want a subset of them.

In your F<dist.ini>:

  [PruneFiles]
  file = xt/release/pod-coverage.t ; pod coverage tests are for jerks

=cut

sub multivalue_args { qw(file) }

=attr filenames

This is an arrayref of filenames to be pruned from the distribution.  It's
initialized by the C<file> argument to the plugin constructor (and, therefore,
in the config).

=cut

has filenames => (
  is   => 'ro',
  isa  => 'ArrayRef',
  lazy => 1,
  init_arg => 'file',
  default  => sub { [] },
);

sub prune_files {
  my ($self) = @_;

  my $files = $self->zilla->files;
  my $any = $self->filenames->any;

  @$files = $files->grep(sub { $_->name ne $any })->flatten;

  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
