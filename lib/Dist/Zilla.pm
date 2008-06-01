package Dist::Zilla;
use Moose;
use Moose::Autobox;
use MooseX::Types::Path::Class qw(Dir File);
use Moose::Util::TypeConstraints;

our $VERSION = '0.001';

use File::Find::Rule;
use Path::Class ();

use Dist::Zilla::Config;

use Dist::Zilla::File::OnDisk;
use Dist::Zilla::Role::Plugin;

has name => (
  is   => 'ro',
  isa  => 'Str',
  required => 1,
);

has license => (
  is   => 'ro',
  isa  => 'Software::License',
  lazy => 1,
  default => sub { die },
);

has authors => (
  is   => 'ro',
  isa  => 'ArrayRef[Str]',
  required => 1,
);

sub from_dir {
  my ($class, $root) = @_;

  $root = Path::Class::dir($root) unless ref $root;

  my $config_file = $root->file('dist.ini');
  my $config = Dist::Zilla::Config->read_file($config_file);

  my $plugins = delete $config->{plugins};

  my $self = $class->new($config->merge({ root => $root }));

  for my $plugin (@$plugins) {
    my ($plugin_class, $arg) = @$plugin;
    $self->plugins->push(
      $plugin_class->new( $arg->merge({ zilla => $self }) )
    );
  }

  return $self;
}

has plugins => (
  is   => 'ro',
  isa  => 'ArrayRef[Dist::Zilla::Role::Plugin]',
  default => sub { [ ] },
);

has files => (
  is   => 'ro',
  isa  => 'ArrayRef',
  lazy => 1,
  default => sub {
    my ($self) = @_;
    my $root = $self->root;
    my @files = File::Find::Rule
              ->not( File::Find::Rule->name(qr/^\./) )
              ->file
              ->in($root);

    return \@files;
  },
);

sub plugins_with {
  my ($self, $role) = @_;

  $role =~ s/^-/Dist::Zilla::Role::/;
  my $plugins = $self->plugins->grep(sub { $_->does($role) });

  return $plugins;
}

has root => (
  is   => 'ro',
  isa  => Dir,
  coerce   => 1,
  required => 1,
);

sub manifest {
  my ($self) = @_;
  
  my $files = [ $self->files->flatten ];

  $_->prune_files($files) for $self->plugins_with(-FilePruner)->flatten;

  return $files;
}

sub build_dist {
  my ($self, $root) = @_;

  my $build_root = Path::Class::dir($root);
  $build_root->mkpath unless -d $build_root;

  my $dist_root = $self->root;
  my $manifest  = $self->manifest;

  my $files = $manifest->map(sub {
    Dist::Zilla::File::OnDisk->new({ name => $_ });
  });

  for ($self->plugins_with(-FileWriter)->flatten) {
    my $new_files = $_->write_files({
      build_root => $build_root,
      dist       => $self,
      manifest   => $manifest,
    });

    $files->push($new_files->flatten);
  }

  for my $file ($files->flatten) {
    $_->munge_file($file) for $self->plugins_with(-FileMunger)->flatten;

    my $_file = Path::Class::file($file->name);

    my $to_dir = $build_root->subdir( $_file->dir );
    my $to = $to_dir->file( $_file->basename );
    $to_dir->mkpath unless -e $to_dir;
    die "not a directory: $to_dir" unless -d $to_dir;
  
    Carp::croak("attempted to write $to multiple times") if -e $to;

    open my $out_fh, '>', "$to" or die "couldn't open $to to write: $!";
    print { $out_fh } $file->content;
    close $out_fh or die "error closing $to: $!";
  }

  for ($self->plugins_with(-AfterBuild)->flatten) {
    $_->after_build({
      build_root => $build_root,
      dist       => $self,
      files      => $files,
    });
  }
}


no Moose;
1;
