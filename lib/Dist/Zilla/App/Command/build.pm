use strict;
use warnings;
package Dist::Zilla::App::Command::build;
use Dist::Zilla::App -command;

sub abstract { 'build your dist' }

sub opt_spec {
  [ 'tgz!', 'build a tarball (default behavior)', { default => 1 } ],
}

sub run {
  my ($self, $opt, $arg) = @_;

  require Archive::Tar;
  require Path::Class;

  my $default_name = $self->zilla->name . '-' . $self->zilla->version;
  my $target = Path::Class::dir($arg->[0] || "./$default_name");
  $target->rmtree if -d $target;

  my $dist = Dist::Zilla->from_dir('.');

  $dist->build_dist($target);

  return unless $opt->{tgz};

  my $archive = Archive::Tar->new;
  $archive->add_files( File::Find::Rule->file->in($target) );
  $archive->write("$default_name.tar.gz", 9);
  $target->rmtree;
}

1;
