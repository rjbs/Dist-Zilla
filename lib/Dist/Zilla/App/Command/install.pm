use strict;
use warnings;
package Dist::Zilla::App::Command::install;
# ABSTRACT: install your dist
use Dist::Zilla::App -command;

sub abstract { 'install your dist' }

sub opt_spec {
  [ 'install-command=s', 'command to run to install (e.g. "cpan .")' ],
}

sub run {
  my ($self, $opt, $arg) = @_;

  require File::chdir;
  require File::Temp;
  require Path::Class;

  my $build_root = Path::Class::dir('.build');
  $build_root->mkpath unless -d $build_root;

  my $target = Path::Class::dir( File::Temp::tempdir(DIR => $build_root) );
  $self->log("building distribution under $target for installation");
  $self->zilla->ensure_built_in($target);

  eval {
    local $File::chdir::CWD = $target;
    my @cmd = $opt->{install_command};
    unless (@cmd) { @cmd = ($^X => '-MCPAN' => '-einstall "."') };
    system(@cmd) && die "error with 'cpan .'\n";
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
