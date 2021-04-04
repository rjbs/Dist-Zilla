package Dist::Zilla::App::Command::version;
# ABSTRACT: display dzil's version

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use Dist::Zilla::App -command;
use App::Cmd::Command::version;
BEGIN {
  ## parent and base dont work here. ??? -- kentnl 2014-10-31
  our @ISA;
  unshift @ISA, 'App::Cmd::Command::version';
}

=head1 SYNOPSIS

Print dzil version

  $ dzil --version or $dzil version

=cut

sub version_for_display {
  my $version_pkg = $_[0]->version_package;
  my $version = ( $version_pkg->VERSION ?
                  $version_pkg->VERSION :
                 'dev' );
}

1;
