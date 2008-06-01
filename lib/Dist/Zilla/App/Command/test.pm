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
  require IPC::System::Simple;
  my $run = \&IPC::System::Simple::run;

  my $target = Path::Class::dir( File::Temp::tempdir() );
  print "> building test distribution under $target\n";

  my $dist = Dist::Zilla->from_dir('.');
  $dist->build_dist($target);

  chdir($target);
  my $output = eval {
    $run->($^X => 'Makefile.PL') . $run->('make') . $run->('make test');
  };

  if ($@) {
    print "> error testing new distribution\n";
    print "> left dist in place\n";
    print $output;
  } else {
    $target->rmtree;
  }
}

1;
