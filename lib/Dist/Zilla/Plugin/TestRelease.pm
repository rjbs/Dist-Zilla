package Dist::Zilla::Plugin::TestRelease;
# ABSTRACT: extract archive and run tests before releasing the dist

use Moose;
with 'Dist::Zilla::Role::BeforeRelease';

use namespace::autoclean;

=head1 DESCRIPTION

This plugin runs before a release happens.  It will extract the to-be-released
archive into a temporary directory and use the TestRunner plugins to run its
tests.  If the tests fail, the release is aborted and the temporary directory
is left in place.  If the tests pass, the temporary directory is cleaned up and
the release process continues.

This will set the RELEASE_TESTING and AUTHOR_TESTING env vars while running the
test suite.

=head1 CREDITS

This plugin was originally contributed by Christopher J. Madsen.

=cut

use File::pushd ();
use Dist::Zilla::Path;

sub before_release {
  my ($self, $tgz) = @_;
  $tgz = $tgz->absolute;

  my $build_root = $self->zilla->root->child('.build');
  $build_root->mkpath unless -d $build_root;

  my $tmpdir = path( File::Temp::tempdir(DIR => $build_root) );

  $self->log("Extracting $tgz to $tmpdir");

  require Archive::Tar;

  my @files = do {
    my $wd = File::pushd::pushd($tmpdir);
    Archive::Tar->extract_archive("$tgz");
  };

  $self->log_fatal([ "Failed to extract archive: %s", Archive::Tar->error ])
    unless @files;

  # Run tests on the extracted tarball:
  my $target = $tmpdir->child( $self->zilla->dist_basename );

  local $ENV{RELEASE_TESTING} = 1;
  local $ENV{AUTHOR_TESTING} = 1;
  $self->zilla->run_tests_in($target);

  $self->log("all's well; removing $tmpdir");
  $tmpdir->remove_tree({ safe => 0 });
}

__PACKAGE__->meta->make_immutable;
1;
