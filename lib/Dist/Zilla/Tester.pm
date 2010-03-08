package Dist::Zilla::Tester;
use Moose;
extends 'Dist::Zilla';

use File::Copy::Recursive qw(dircopy);
use File::chdir;
use File::Spec;
use File::Temp;
use Path::Class;

around from_config => sub {
  my ($orig, $self, $orig_arg) = @_;

  my $arg = { %{ $orig_arg || {} } };
  delete $arg->{dist_root};

  local @INC = map {; ref($_) ? $_ : File::Spec->rel2abs($_) } @INC;

  confess "dist_root required for from_config" unless $orig_arg->{dist_root};
  my $source = $orig_arg->{dist_root};

  my $tempdir ||= dir( File::Temp::tempdir(CLEANUP => 1) );

  my $root = $tempdir->subdir('source');
  $root->mkpath;

  dircopy($source, $root);

  $arg->{dist_root} = "$root";

  my $zilla = $self->$orig($arg);

  $zilla->_set_tempdir($tempdir);

  return $zilla;
};

around build_in => sub {
  my ($orig, $self, $target) = @_;

  # XXX: We *must eliminate* the need for this!  It's only here because right
  # now building a dist with (root <> cwd) doesn't work. -- rjbs, 2010-03-08
  local $CWD = $self->root;

  $target ||= do {
    my $target = dir($self->tempdir)->subdir('build');
    $target->mkpath;
    $target;
  };

  return $self->$orig($target);
};

has tempdir => (
  is   => 'ro',
  writer   => '_set_tempdir',
  init_arg => undef,
);

1;
