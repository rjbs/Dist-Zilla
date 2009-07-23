use strict;
use warnings;
package Dist::Zilla::App::Command::install;
# ABSTRACT: install your dist
use Dist::Zilla::App -command;

=head1 SYNOPSIS

Installs your distribution using a specified command.

    dzil install [--install-command="cmd"]

=cut
sub abstract { 'install your dist' }

=head1 EXAMPLE

    $ dzil install
    $ dzil install --install-command="cpan ."

=cut

sub opt_spec {
  [ 'install-command=s', 'command to run to install (e.g. "cpan .")' ],
}

=head1 OPTIONS

=head2 --install-command

This defines what command to run after building the dist in the dist dir.

Any value that works with L<C<system>|perlfunc/system> is accepted.

If not specified, calls

    perl -MCPAN -einstall "."

=cut


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
    ## no critic Punctuation
    local $File::chdir::CWD = $target;
    my @cmd = $opt->{install_command}
            ? $opt->{install_command}
            : ($^X => '-MCPAN' => '-einstall "."');

    system(@cmd) && die "error with '@cmd'\n";
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
