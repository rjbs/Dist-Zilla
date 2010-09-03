package Dist::Zilla::Plugin::PruneCruft;
# ABSTRACT: prune stuff that you probably don't mean to include
use Moose;
use Moose::Autobox;
use Moose::Util::TypeConstraints;
with 'Dist::Zilla::Role::FilePruner';

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
  for my $exception ($self->except->flatten) {
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
  return 1 if $file->name eq 'MYMETA.yml';
  return;
}

sub prune_files {
  my ($self) = @_;

  for my $file ($self->zilla->files->flatten) {
    next unless $self->exclude_file($file);

    $self->log_debug([ 'pruning %s', $file->name ]);

    $self->zilla->prune_file($file);
  }

  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
