use strict;
use warnings;
package Dist::Zilla::App::Command::build;
use Dist::Zilla::App -command;

sub abstract { 'build your dist' }

sub run {
  my ($self, $opt, $arg) = @_;

  require Dist::Zilla;
  require Path::Class;

  my $target = Path::Class::dir($arg->[0] || './dist');

  $target->rmtree if -d $target;

  my $dist = Dist::Zilla->from_dir('.');

  $dist->build_dist($target);
}

1;
