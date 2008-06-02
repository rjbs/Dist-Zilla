use strict;
use warnings;
package Dist::Zilla::App::Command::test;
use Dist::Zilla::App -command;

sub abstract { 'test your dist' }

sub run {
  my ($self, $opt, $arg) = @_;

  require Dist::Zilla;
  require File::Temp;
  require Path::Class;

  my $dist = Dist::Zilla->from_dir('.');

  my $build_root = $dist->build_root;
  $build_root->mkpath unless -d $build_root;

  my $target = Path::Class::dir( File::Temp::tempdir(DIR => $build_root) );
  print "> building test distribution under $target\n";

  $dist->build_dist($target);

  chdir($target);
  eval {
    system($^X => 'Makefile.PL') and die "> error with Makefile.PL\n";
    system('make') and die "> error running make\n";
    system('make test') and die "> error running make test\n";
  };

  if ($@) {
    print $@;
    print "> left failed dist in place at $target\n";
  } else {
    $target->rmtree;
  }
}

1;
