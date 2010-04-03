package Dist::Zilla::Tester;
use Moose;
extends 'Dist::Zilla';
# ABSTRACT: a testing-enabling stand-in for  Dist::Zilla

use autodie;
use File::Copy::Recursive qw(dircopy);
use File::chdir;
use File::Spec;
use File::Temp;
use Path::Class;

around from_config => sub {
  my ($orig, $self, $arg, $tester_arg) = @_;

  confess "dist_root required for from_config" unless $arg->{dist_root};

  my $source = $arg->{dist_root};

  my $tempdir_root = exists $tester_arg->{tempdir_root}
                   ? $tester_arg->{tempdir_root}
                   : 'tmp';

  mkdir $tempdir_root if defined $tempdir_root and not -d $tempdir_root;

  my $tempdir = dir( File::Temp::tempdir(
      CLEANUP => 1,
      (defined $tempdir_root ? (DIR => $tempdir_root) : ()),
  ))->absolute;

  my $root = $tempdir->subdir('source');
  $root->mkpath;

  dircopy($source, $root);

  if ($tester_arg->{also_copy}) {
    while (my ($src, $dest) = each %{ $tester_arg->{also_copy} }) {
      dircopy($src, $tempdir->subdir($dest));
    }
  }

  if (my $files = $tester_arg->{add_files}) {
    while (my ($name, $content) = each %$files) {
      my $fn = $tempdir->file($name);
      $fn->dir->mkpath;
      open my $fh, '>', $fn;
      print { $fh } $content;
      close $fh;
    }
  }

  local $arg->{dist_root} = "$root";
  local $arg->{interface} = Dist::Zilla::Tester::UI->new;

  local @INC = map {; ref($_) ? $_ : File::Spec->rel2abs($_) } @INC;

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

around release => sub {
  my ($orig, $self) = @_;

  # XXX: We *must eliminate* the need for this!  It's only here because right
  # now building a dist with (root <> cwd) doesn't work. -- rjbs, 2010-03-08
  local $CWD = $self->root;

  return $self->$orig;
};


{
  package
    Dist::Zilla::Tester::UI;

  use Moose;
  has logger => (
    is => 'ro',
    default => sub {
      Log::Dispatchouli->new({
        ident   => 'Dist::Zilla::Tester',
        log_pid => 0,
        to_self => 1,
      });
    }
  );
}

has tempdir => (
  is   => 'ro',
  writer   => '_set_tempdir',
  init_arg => undef,
);

sub clear_log_events {
  my ($self) = @_;
  $self->interface->logger->clear_events;
}

sub log_events {
  my ($self) = @_;
  $self->interface->logger->events;
}

sub log_messages {
  my ($self) = @_;
  [ map {; $_->{message} } @{ $self->interface->logger->events } ];
}

sub slurp_file {
  my ($self, $filename) = @_;

  return scalar do {
    local $/;
    open my $fh, '<', $self->tempdir->file($filename);
    <$fh>;
  };
}

1;
