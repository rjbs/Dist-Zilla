package Dist::Zilla::Plugin::ManifestSkip;
# ABSTRACT: decline to build files that appear in a MANIFEST.SKIP-like file

use Moose;
with 'Dist::Zilla::Role::FilePruner';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

=head1 DESCRIPTION

This plugin reads a MANIFEST.SKIP-like file, as used by L<ExtUtils::MakeMaker>
and L<ExtUtils::Manifest>, and prunes any files that it declares should be
skipped.

This plugin is included in the L<@Basic|Dist::Zilla::PluginBundle::Basic>
bundle.

=attr skipfile

This is the name of the file to read for MANIFEST.SKIP-like content.  It
defaults, unsurprisingly, to F<MANIFEST.SKIP>.

=head1 SEE ALSO

Dist::Zilla core plugins:
L<@Basic|Dist::Zilla::PluginBundle::Basic>,
L<PruneCruft|Dist::Zilla::Plugin::PruneCruft>,
L<PruneFiles|Dist::Zilla::Plugin::PruneFiles>.

Other modules: L<ExtUtils::Manifest>.

=cut

has skipfile => (is => 'ro', required => 1, default => 'MANIFEST.SKIP');

sub prune_files {
  my ($self) = @_;
  my $files = $self->zilla->files;

  my $skipfile_name = $self->skipfile;
  my ($skipfile) = grep { $_->name eq $skipfile_name } @$files;
  unless (defined $skipfile) {
    $self->log_debug([ 'file %s not found', $skipfile_name ]);
    return;
  }

  my $content = $skipfile->content;

  # If the content has been generated in memory or changed from disk,
  # create a temp file with the content.
  # (Unfortunately maniskip can't read from a string ref)
  my $fh;
  if (! -f $skipfile_name || (-s $skipfile_name) != length($content)) {
    $fh = File::Temp->new;
    $skipfile_name = $fh->filename;
    $self->log_debug([ 'create temporary %s', $skipfile_name ]);
    print $fh $content;
    close $fh;
  }

  require ExtUtils::Manifest;
  ExtUtils::Manifest->VERSION('1.54');

  my $skip = ExtUtils::Manifest::maniskip($skipfile_name);

  # Copy list (break reference) so we can mutate.
  for my $file ((), @{ $files }) {
    next unless $skip->($file->name);

    $self->log_debug([ 'pruning %s', $file->name ]);

    $self->zilla->prune_file($file);
  }

  return;
}

__PACKAGE__->meta->make_immutable;
1;
