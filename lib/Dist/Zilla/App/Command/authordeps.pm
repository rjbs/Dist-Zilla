use strict;
use warnings;
package Dist::Zilla::App::Command::authordeps;
# ABSTRACT: List your distribution's author dependencies

use Dist::Zilla::App -command;

use Dist::Zilla::Dialect;

=head1 SYNOPSIS

  $ dzil authordeps

This will scan the F<dist.ini> file and print a list of plugin modules that
probably need to be installed for the dist to be buildable.  This is a very
naive scan, but tends to be pretty accurate.  Modules can be added to its
results by using special comments in the form:

  ; authordep Some::Package

=cut

sub abstract { "list your distribution's author dependencies" }

sub opt_spec {
  return (
    [ 'root=s' => 'the root of the dist; defaults to .' ],
    [ 'missing' => 'list only the missing dependencies' ],
    [ 'versions' => 'include required version numbers in listing' ],
  );
}

sub execute ($self, $opt, $arg) {
  require Dist::Zilla::Path;
  require Dist::Zilla::Util::AuthorDeps;

  my $deps = Dist::Zilla::Util::AuthorDeps::format_author_deps(
    Dist::Zilla::Util::AuthorDeps::extract_author_deps(
      Dist::Zilla::Path::path($opt->root // '.'),
      $opt->missing,
    ), $opt->versions
  );

  $self->log($deps) if $deps;

  return;
}

1;
