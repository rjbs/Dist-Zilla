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

  my $target = Path::Class::dir( File::Temp::tempdir );
  print "> building test distribution under $target\n";

  my $dist = Dist::Zilla->from_dir('.');
  $dist->build_dist($target);

  chdir($target);
  print `$^X Makefile.PL`;
  print `make`;
  print `make test`;

  $target->rmtree;
}

1;
