package Dist::Zilla::Plugin::GatherFile;
# ABSTRACT: gather individual file(s)

use Moose;
use Dist::Zilla::Types qw(Path ArrayRefOfPaths);
with 'Dist::Zilla::Role::FileGatherer';

use Dist::Zilla::Dialect;

use MooseX::Types::Moose 'ArrayRef';
use Path::Tiny;
use Dist::Zilla::File::OnDisk;
use Dist::Zilla::Util;
use namespace::autoclean;

=head1 SYNOPSIS

  [GatherFile]
  filename = examples/file.txt

=head1 DESCRIPTION

This is a very, very simple L<FileGatherer|Dist::Zilla::Role::FileGatherer>
plugin.  It adds all the files referenced by the C<filename> option that are
found in the directory named in the L</root> attribute.  If the root begins
with a tilde, the tilde is passed through C<glob()> first.

Since normally every distribution will use a GatherDir plugin, you would only
need to use the GatherFile plugin if the file was already being excluded (e.g.
from an C<exclude_match> configuration).

=cut

=attr root

This is the directory in which to look for files.  If not given, it defaults to
the dist root -- generally, the place where your F<dist.ini> or other
configuration file is located.

=cut

has root => (
  is   => 'ro',
  isa  => Path,
  lazy => 1,
  coerce   => 1,
  required => 1,
  default  => sub { shift->zilla->root },
);

=attr prefix

This parameter can be set to place the gathered files under a particular
directory.  See the L<description|DESCRIPTION> above for an example.

=cut

has prefix => (
  is  => 'ro',
  isa => 'Str',
  default => '',
);

=attr filename

The name of the file to gather, relative to the C<root>.
Can be used more than once.

=cut

has filenames => (
  is => 'ro', isa => ArrayRefOfPaths,
  lazy => 1,
  coerce => 1,
  default => sub { [] },
);

sub mvp_aliases { +{ filename => 'filenames' } }
sub mvp_multivalue_args { qw(filenames) }

around dump_config => sub {
  my $orig = shift;
  my $self = shift;

  my $config = $self->$orig;

  $config->{+__PACKAGE__} = {
    prefix => $self->prefix,
    # only report relative to dist root to avoid leaking private info
    root => path($self->root)->relative($self->zilla->root),
    filenames => [ sort @{ $self->filenames } ],
  };

  return $config;
};

sub gather_files {
  my ($self) = @_;

  my $repo_root = $self->zilla->root;
  my $root = "" . $self->root;
  $root =~ s{^~([\\/])}{ Dist::Zilla::Util->homedir . $1 }e;
  $root = path($root);
  $root = $root->absolute($repo_root) if path($root)->is_relative;

  for my $filename (@{ $self->filenames })
  {
    $filename = $root->child($filename);
    $self->log_fatal("$filename is a directory! Use [GatherDir] instead?") if -d $filename;

    my $fileobj = $self->_file_from_filename($filename->stringify);

    $filename = $fileobj->name;
    my $file = path($filename)->relative($root);
    $file = path($self->prefix, $file) if $self->prefix;

    $fileobj->name($file->stringify);
    $self->add_file($fileobj);
  }

  return;
}

# as in GatherDir
sub _file_from_filename {
  my ($self, $filename) = @_;

  my @stat = stat $filename or $self->log_fatal("$filename does not exist!");

  return Dist::Zilla::File::OnDisk->new({
    name => $filename,
    mode => $stat[2] & 0755, # kill world-writeability
  });
}

__PACKAGE__->meta->make_immutable;
