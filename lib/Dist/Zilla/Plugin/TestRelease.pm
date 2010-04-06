package Dist::Zilla::Plugin::TestRelease;
use Moose;
with 'Dist::Zilla::Role::BeforeRelease';

use Archive::Tar;
use File::pushd ();
use Moose::Autobox;
use Path::Class ();

sub before_release {
  my ($self, $tgz) = @_;
  $tgz = $tgz->absolute;

  my $build_root = $self->zilla->root->subdir('.build');
  $build_root->mkpath unless -d $build_root;

  my $tmpdir = Path::Class::dir( File::Temp::tempdir(DIR => $build_root) );

  $self->log("Extracting $tgz to $tmpdir");

  my @files = do {
    my $wd = File::pushd::pushd($tmpdir);
    Archive::Tar->extract_archive("$tgz");
  };

  $self->log_fatal([ "Failed to extract archive: %s", Archive::Tar->error ])
    unless @files;

  # Run tests on the extracted tarball:
  my $target = $tmpdir->subdir($files[0]); # Should be the root of the tarball

  local $ENV{RELEASE_TESTING} = 1;
  $self->zilla->run_tests_in($target);

  $self->log("all's well; removing $tmpdir");
  $tmpdir->rmtree;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
