use strict;
use warnings;
package Dist::Zilla::Command::build;
use Dist::Zilla::App -command;

sub abstract { 'build your dist' }

sub run {
  my ($self, $opt, $arg) = @_;

  require Dist::Zilla;
  require Path::Class;

  my $root   = Path::Class::dir($arg->[0] || '.');
  my $target = Path::Class::dir($arg->[1] || './dist');

  $target->rmtree if -d $target;

  my $dist = Dist::Zilla->from_dir($root);

  $dist->build_dist($target);
}

1;
