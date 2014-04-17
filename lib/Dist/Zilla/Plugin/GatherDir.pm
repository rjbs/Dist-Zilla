package Dist::Zilla::Plugin::GatherDir;
# ABSTRACT: gather all the files in a directory

use Moose;
use Moose::Autobox;
use MooseX::Types::Path::Class qw(Dir File);
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

...and this will pick up all the files from the current directory into the
dist.  You can use it multiple times, as you can any other plugin, by providing
a plugin name.  For example, if you want to include external specification
files into a subdir of your dist, you might write:

  [GatherDir]
  ; this plugin needs no config and gathers most of your files

  [GatherDir / SpecFiles]
  ; this plugin gets all the files in the root dir and adds them under ./spec
  root   = ~/projects/my-project/spec
  prefix = spec

=cut

use File::Find::Rule;
use File::Spec;
use Path::Class;

use namespace::autoclean;

=attr root

This is the directory in which to look for files.  If not given, it defaults to
the dist root -- generally, the place where your F<dist.ini> or other
configuration file is located.

=cut

has root => (
  is   => 'ro',
  isa  => Dir,
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

By default, directories that are symlinks will not be followed. Note on the
other hand that in all followed directories, files which are symlinks are
always gathered.

=cut

has follow_symlinks => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

sub mvp_multivalue_args { qw(exclude_filename exclude_match) }

=attr exclude_filename

To exclude certain files from being gathered, use the C<exclude_filename>
option. This may be used multiple times to specify multiple files to exclude.

=cut

has exclude_filename => (
  is   => 'ro',
  isa  => 'ArrayRef',
  default => sub { [] },
);

=attr exclude_match

This is just like C<exclude_filename> but provides a regular expression
pattern.  Files matching the pattern are not gathered.  This may be used
multiple times to specify multiple patterns to exclude.

=cut

has exclude_match => (
  is   => 'ro',
  isa  => 'ArrayRef',
  default => sub { [] },
);

sub gather_files {
  my ($self) = @_;

  my $exclude_regex = qr/\000/;
  $exclude_regex = qr/$exclude_regex|$_/
    for ($self->exclude_match->flatten);

  my %is_excluded = map {; $_ => 1 } $self->exclude_filename->flatten;

  my $root = "" . $self->root;
  $root =~ s{^~([\\/])}{require File::HomeDir; File::HomeDir::->my_home . $1}e;
  $root = Path::Class::dir($root);

  my $rule = File::Find::Rule->new();
  $rule->extras({follow => $self->follow_symlinks});
  FILE: for my $filename ($rule->file->in($root)) {
    my $file = file($filename)->relative($root);

    unless ($self->include_dotfiles) {
      next FILE if $file->basename =~ qr/^\./;
      next FILE if grep { /^\.[^.]/ } $file->dir->dir_list;
    }

    next if $file =~ $exclude_regex;
    next if $is_excluded{ $file };

    # _file_from_filename is overloaded in GatherDir::Template
    my $fileobj = $self->_file_from_filename($filename);

    $file = Path::Class::file($self->prefix, $file) if $self->prefix;

    $fileobj->name($file->as_foreign('Unix')->stringify);
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
