package Dist::Zilla::App::Command::authordeps;
# ABSTRACT: List your distribution's author dependencies

use Dist::Zilla::Pragmas;

use Dist::Zilla::App -command;

=head1 SYNOPSIS

  $ dzil authordeps

This will scan the F<dist.ini> file and print a list of plugin modules that
probably need to be installed for the dist to be buildable.  This is a very
naive scan, but tends to be pretty accurate.  Modules can be added to its
results by using special comments in the form:

  ; authordep Some::Package

In order to add authordeps to all distributions that use a certain plugin bundle
(or plugin), just list them as prereqs of that bundle (e.g.: using
L<Dist::Zilla::Plugin::Prereqs> ).

=cut

sub abstract { "list your distribution's author dependencies" }

sub opt_spec {
  return (
    [ 'root=s' => 'the root of the dist; defaults to .' ],
    [ 'missing' => 'list only the missing dependencies' ],
    [ 'versions' => 'include required version numbers in listing' ],
    [ 'cpanm-versions' => 'format versions for consumption by cpanm' ],
  );
}

sub execute {
  my ($self, $opt, $arg) = @_;

  require Dist::Zilla::Path;
  require Dist::Zilla::Util::AuthorDeps;

  my $deps = Dist::Zilla::Util::AuthorDeps::_format_author_deps(
    Dist::Zilla::Util::AuthorDeps::_extract_author_deps(
      Dist::Zilla::Path::path($opt->root // '.'),
      $opt->missing,
    ),
    $opt->versions,
    $opt->cpanm_versions
  );

  $self->log($deps) if $deps;

  return;
}

1;
