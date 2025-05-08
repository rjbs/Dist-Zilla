package Dist::Zilla::Plugin::PruneCruft;
# ABSTRACT: prune stuff that you probably don't mean to include

use Moose;
use Moose::Util::TypeConstraints;
with 'Dist::Zilla::Role::FilePruner';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

=head1 SYNOPSIS

This plugin tries to compensate for the stupid crap that turns up in your
working copy, removing it before it gets into your dist and screws everything
up.

In your F<dist.ini>:

  [PruneCruft]

If you would like to exclude certain exclusions, use the C<except> option (it
can be specified multiple times):

  [PruneCruft]
  except = \.gitignore
  except = t/.*/\.keep$

This plugin is included in the L<@Basic|Dist::Zilla::PluginBundle::Basic>
bundle.

=head1 SEE ALSO

Dist::Zilla plugins:
L<@Basic|Dist::Zilla::PluginBundle::Basic>,
L<PruneFiles|Dist::Zilla::Plugin::PruneFiles>,
L<ManifestSkip|Dist::Zilla::Plugin::ManifestSkip>.

=cut

{
  my $type = subtype as 'ArrayRef[RegexpRef]';
  coerce $type, from 'ArrayRef[Str]', via { [map { qr/$_/ } @$_] };
  has except => (
    is      => 'ro',
    isa     => $type,
    coerce  => 1,
    default => sub { [] },
  );
  sub mvp_multivalue_args { qw(except) }
}

sub _dont_exclude_file {
  my ($self, $file) = @_;
  for my $exception (@{ $self->except }) {
    return 1 if $file->name =~ $exception;
  }
  return;
}

sub exclude_file {
  my ($self, $file) = @_;

  return 0 if $self->_dont_exclude_file($file);
  return 1 if index($file->name, $self->zilla->name . '-') == 0;
  return 1 if $file->name =~ /\A\./;
  return 1 if $file->name =~ /\A(?:Build|Makefile)\z/;
  return 1 if $file->name eq 'Makefile.old';
  return 1 if $file->name =~ /\Ablib/;
  return 1 if $file->name =~ /\.(?:o|bs)$/;
  return 1 if $file->name =~ /\A_Inline/;
  return 1 if $file->name eq 'MYMETA.yml';
  return 1 if $file->name eq 'MYMETA.json';
  return 1 if substr($file->name, -12) eq 'perltidy.ERR';
  return 1 if $file->name eq 'pm_to_blib';
  return 1 if substr($file->name, 0, 6) eq '_eumm/';
  # Avoid bundling fatlib/ dir created by App::FatPacker
  # https://github.com/andk/pause/pull/65
  return 1 if substr($file->name, 0, 7) eq 'fatlib/';
  return 1 if substr($file->name, 0, 4) eq 'tmp/';

  if (my $file = $file->name =~ s/\.c$//r) {
    for my $other (@{ $self->zilla->files }) {
      return 1 if $other->name eq "${file}.xs";
    }
  }

  return;
}

sub prune_files {
  my ($self) = @_;

  # Copy list (break reference) so we can mutate.
  for my $file ((), @{ $self->zilla->files }) {
    next unless $self->exclude_file($file);

    $self->log_debug([ 'pruning %s', $file->name ]);

    $self->zilla->prune_file($file);
  }

  return;
}

__PACKAGE__->meta->make_immutable;
1;
