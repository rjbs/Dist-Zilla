use strict;
use warnings;
package Dist::Zilla::App::Command::install;
# ABSTRACT: install your dist
use Dist::Zilla::App -command;

sub abstract { 'install your dist' }

sub run {
  my ($self, $opt, $arg) = @_;

  require Dist::Zilla;
  require File::chdir;
  require File::Temp;
  require Path::Class;

  my $build_root = Path::Class::dir('.build');
  $build_root->mkpath unless -d $build_root;

  my $target = Path::Class::dir( File::Temp::tempdir(DIR => $build_root) );
  $self->log("building distribution under $target");

  $self->zilla->ensure_built_in($target);

  eval {
    ## no critic Punctuation
    local $File::chdir::CWD = $target;
    system($^X => 'Makefile.PL') and die "error with Makefile.PL\n";
    system('make') and die "error running make\n";
    system('make install') and die "error running make install\n";
  };

  if ($@) {
    $self->log($@);
    $self->log("left failed dist in place at $target");
  } else {
    $self->log("all's well; removing $target");
    $target->rmtree;
  }
}

1;
