package Dist::Zilla::Plugin::GatherDir;
# ABSTRACT: gather all the files in a directory

use Moose;
use Dist::Zilla::Types qw(Path);
with 'Dist::Zilla::Role::FileGatherer';

use namespace::autoclean;

=head1 DESCRIPTION

This is a very, very simple L<FileGatherer|Dist::Zilla::Role::FileGatherer>
plugin.  It looks in the directory named in the L</root> attribute and adds all
the files it finds there.  If the root begins with a tilde, the tilde is
replaced with the current user's home directory according to L<File::HomeDir>.

Almost every dist will be built with one GatherDir plugin, since it's the
easiest way to get files from disk into your dist.  Most users just need:

  [GatherDir]
  [PruneCruft]

...and this will pick up all the files from the current directory into the
dist.  (L<PruneCruft|Dist::Zilla::Plugin::PruneCruft> is needed, here, to drop
files that might present as build artifacts, but should not be shipped.)  You
can use it multiple times, as you can any other plugin, by providing a plugin
name.  For example, if you want to include external specification files into a
subdir of your dist, you might write:

  [GatherDir]
  ; this plugin needs no config and gathers most of your files

  [GatherDir / SpecFiles]
  ; this plugin gets all the files in the root dir and adds them under ./spec
  root   = ~/projects/my-project/spec
  prefix = spec

=cut

use File::Find::Rule;
use File::Spec;
use Path::Tiny;
use List::Util 1.33 'all';

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

=attr include_dotfiles

By default, files will not be included if they begin with a dot.  This goes
both for files and for directories relative to the C<root>.

In almost all cases, the default value (false) is correct.

=cut

has include_dotfiles => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

=attr follow_symlinks

By default, symlinks pointing to directories will not be followed; set
C<< follow_symlinks = 1 >> to traverse these links as if they were normal
directories.

In all followed directories, files which are symlinks are B<always> gathered,
with the link turning into a normal file.

=cut

has follow_symlinks => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

sub mvp_multivalue_args { qw(exclude_filename exclude_match prune_directory) }

=attr exclude_filename

To exclude certain files from being gathered, use the C<exclude_filename>
option.  The filename is matched exactly, relative to C<root>.
This may be used multiple times to specify multiple files to exclude.

=cut

has exclude_filename => (
  is   => 'ro',
  isa  => 'ArrayRef',
  default => sub { [] },
);

=attr exclude_match

This is just like C<exclude_filename> but provides a regular expression
pattern.  Filenames matching the pattern (relative to C<root>)  are not
gathered.  This may be used
multiple times to specify multiple patterns to exclude.

=cut

has exclude_match => (
  is   => 'ro',
  isa  => 'ArrayRef',
  default => sub { [] },
);

=attr prune_directory

While traversing, any directory matching the regular expression pattern will
not be traversed further. This may be used multiple times to specify multiple
directories to skip.

=cut

has prune_directory => (
  is   => 'ro',
  isa  => 'ArrayRef',
  default => sub { [] },
);

around dump_config => sub {
  my $orig = shift;
  my $self = shift;

  my $config = $self->$orig;

  $config->{+__PACKAGE__} = {
    prefix => $self->prefix,
    # only report relative to dist root to avoid leaking private info
    root => path($self->root)->relative($self->zilla->root),
    (map { $_ => $self->$_ ? 1 : 0 } qw(include_dotfiles follow_symlinks)),
    (map { $_ => [ sort @{ $self->$_ } ] } qw(exclude_filename exclude_match prune_directory)),
  };

  return $config;
};

sub gather_files {
  my ($self) = @_;

  my $exclude_regex = qr/\000/;
  $exclude_regex = qr/(?:$exclude_regex)|$_/
    for @{ $self->exclude_match };

  my $repo_root = $self->zilla->root;
  my $root = "" . $self->root;
  $root =~ s{^~([\\/])}{require File::HomeDir; File::HomeDir::->my_home . $1}e;
  $root = path($root)->absolute($repo_root)->stringify if path($root)->is_relative;

  my $prune_regex = qr/\000/;
  $prune_regex = qr/$prune_regex|$_/
    for ( @{ $self->prune_directory },
      $self->include_dotfiles ? () : ( qr/^\.[^.]/ ) );

  # build up the rules
  my $rule = File::Find::Rule->new();
  $rule->extras({ follow => $self->follow_symlinks });

  $rule->exec(sub { $self->log_debug('considering ' . path($_[-1])->relative($repo_root)); 1 })
    if $self->zilla->logger->get_debug;

  $rule->or(
    $rule->new->directory->exec(sub { /$prune_regex/ })->prune->discard,
    $rule->new,
  );

  if ($self->follow_symlinks) {
    $rule->or(
      $rule->new->file,     # symlinks to files still count as files
      $rule->new->symlink,  # traverse into the linked dir, but screen it out later
    );
  } else {
    $rule->file;
  }

  $rule->not_exec(sub { /^\.[^.]/ }) unless $self->include_dotfiles;   # exec passes basename as $_
  $rule->exec(sub {
    my $relative = path($_[-1])->relative($root);
    $relative !~ $exclude_regex &&
      all { $relative ne $_ } @{ $self->exclude_filename }
  });

  FILE: for my $filename ($rule->in($root)) {
    next if -d $filename;

    # _file_from_filename is overloaded in GatherDir::Template
    my $fileobj = $self->_file_from_filename($filename);

    # GatherDir::Template may rename the file
    $filename = $fileobj->name;
    my $file = path($filename)->relative($root);
    $file = path($self->prefix, $file) if $self->prefix;

    $fileobj->name($file->stringify);
    $self->add_file($fileobj);
  }

  return;
}

sub _file_from_filename {
  my ($self, $filename) = @_;

  my @stat = stat $filename or $self->log_fatal("$filename does not exist!");

  return Dist::Zilla::File::OnDisk->new({
    name => $filename,
    mode => $stat[2] & 0755, # kill world-writeability
  });
}

__PACKAGE__->meta->make_immutable;
1;
