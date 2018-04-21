package Dist::Zilla::Plugin::PruneFiles;
# ABSTRACT: prune arbitrary files from the dist

use Moose;
with 'Dist::Zilla::Role::FilePruner';

use Dist::Zilla::Dialect;

use namespace::autoclean;

=head1 SYNOPSIS

This plugin allows you to explicitly prune some files from your
distribution. You can either specify the exact set of files (with the
"filenames" parameter) or provide the regular expressions to
check (using "match").

This is useful if another plugin (maybe a FileGatherer) adds a
bunch of files, and you only want a subset of them.

In your F<dist.ini>:

  [PruneFiles]
  filename = xt/release/pod-coverage.t ; pod coverage tests are for jerks
  filename = todo-list.txt             ; keep our secret plans to ourselves

  match     = ^test_data/
  match     = ^test.cvs$

=cut

sub mvp_multivalue_args { qw(filenames matches) }
sub mvp_aliases { return { filename => 'filenames', match => 'matches' } }

=attr filenames

This is an arrayref of filenames to be pruned from the distribution.

=cut

has filenames => (
  is   => 'ro',
  isa  => 'ArrayRef',
  default => sub { [] },
);

=attr matches

This is an arrayref of regular expressions and files matching any of them,
will be pruned from the distribution.

=cut

has matches => (
  is   => 'ro',
  isa  => 'ArrayRef',
  default => sub { [] },
);

sub prune_files {
  my ($self) = @_;

  # never match (at least the filename characters)
  my $matches_regex = qr/\000/;

  $matches_regex = qr/$matches_regex|$_/ for ($self->matches->@*);

  # \A\Q$_\E should also handle the `eq` check
  $matches_regex = qr/$matches_regex|\A\Q$_\E/ for ($self->filenames->@*);

  # Copy list (break reference) so we can mutate.
  for my $file ((), @{ $self->zilla->files }) {
    next unless $file->name =~ $matches_regex;

    $self->log_debug([ 'pruning %s', $file->name ]);

    $self->zilla->prune_file($file);
  }

  return;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 SEE ALSO

Dist::Zilla plugins:
L<PruneCruft|Dist::Zilla::Plugin::PruneCruft>,
L<GatherDir|Dist::Zilla::Plugin::GatherDir>,
L<ManifestSkip|Dist::Zilla::Plugin::ManifestSkip>.

=cut
