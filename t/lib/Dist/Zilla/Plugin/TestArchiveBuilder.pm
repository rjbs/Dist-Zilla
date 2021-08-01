package Dist::Zilla::Plugin::TestArchiveBuilder;

use Moose;
use Path::Tiny qw( path );
use JSON::MaybeXS qw( encode_json );
with(
  'Dist::Zilla::Role::ArchiveBuilder',
);

sub build_archive {
  my ($self, $archive_basename, $built_in, $basedir) = @_;

  # instead of archiving in gzip compressed tarball
  # we are writing a fooball archive.
  my $fooball = path($archive_basename . ".foo");

  $fooball->spew_raw(
    encode_json(
      [ $archive_basename, "$built_in", "$basedir" ],
    ),
  );

  return $fooball;
}

__PACKAGE__->meta->make_immutable;
1;
