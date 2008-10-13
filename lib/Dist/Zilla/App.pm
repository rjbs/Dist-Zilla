use strict;
use warnings;
package Dist::Zilla::App;
# ABSTRACT: Dist::Zilla's App::Cmd
use App::Cmd::Setup -app;

use Carp ();
use Dist::Zilla::Config::INI;
use File::HomeDir ();
use Path::Class;

sub config {
  my ($self) = @_;

  my $homedir = File::HomeDir->my_home
    or Carp::croak("couldn't determine home directory");

  my $file = dir($homedir)->file('.dzil');

  if (-d $file) {
    $file = dir($homedir)->subdir('.dzil')->file('config');
  }

  return {} unless -f $file;

  Dist::Zilla::Config::INI->new->read_file($file);
}

1;
