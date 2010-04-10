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
  filenames = xt/release/pod-coverage.t ; pod coverage tests are for jerks

=cut

sub mvp_multivalue_args { qw(filenames) }
sub mvp_aliases { return { filename => 'filenames' } }

=attr filenames

This is an arrayref of filenames to be pruned from the distribution.

=cut

has filenames => (
  is   => 'ro',
  isa  => 'ArrayRef',
  required => 1,
);

sub prune_files {
  my ($self) = @_;

  my $files = $self->zilla->files;

  for my $filename ($self->filenames->flatten) {
    @$files = $files->grep(sub {
      (($_->name ne $filename) && ($_->name !~ m{\A\Q$filename\E/}))
      ? 1
      : do { $self->log_debug([ 'pruning %s', $_->name ]); 0 }
    })->flatten;
  }

  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
