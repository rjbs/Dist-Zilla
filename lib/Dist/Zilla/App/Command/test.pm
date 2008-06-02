use strict;
use warnings;
package Dist::Zilla::App::Command::test;
use Dist::Zilla::App -command;

sub abstract { 'test your dist' }

sub run {
  my ($self, $opt, $arg) = @_;

  require Dist::Zilla;
  require File::chdir;
  require File::Temp;
  require Path::Class;

  my $build_root = $self->zilla->build_root;
  $build_root->mkpath unless -d $build_root;

  my $target = Path::Class::dir( File::Temp::tempdir(DIR => $build_root) );
  $self->log("> building test distribution under $target");

  $self->zilla->build_dist($target);

  eval {
    local $File::chdir::CWD = $target;
    system($^X => 'Makefile.PL') and die "> error with Makefile.PL\n";
    system('make') and die "> error running make\n";
    system('make test') and die "> error running make test\n";
  };

  if ($@) {
    $self->log($@);
    $self->log("> left failed dist in place at $target");
  } else {
    $self->log("> all's well; removing $target);
    $target->rmtree;
  }
}

1;
