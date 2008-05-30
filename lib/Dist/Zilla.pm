package Dist::Zilla;
use Moose;
use Moose::Autobox;
use MooseX::Types::Path::Class qw(Dir File);

our $VERSION = '0.001';

use File::Find::Rule;
use Path::Class ();

use Dist::Zilla::Config;

use Dist::Zilla::File::OnDisk;
use Dist::Zilla::Role::Plugin;

# XXX: should come from config!
has name => (
  is   => 'ro',
  isa  => 'Str',
  required => 1,
);

sub from_dir {
  my ($class, $root) = @_;

  $root = Path::Class::dir($root) unless ref $root;

  my $config_file = $root->file('dist.ini');

  my $ini = Dist::Zilla::Config->read_file($config_file);

  my $config = $ini->[0]{'=name'} eq '_' ? shift @$ini : {};

  my $self = $class->new({ %$config, root => $root });

  my @plugins;
  for my $plugin (@$ini) {
    my $name  = delete $plugin->{'=name'};
    my $class = delete $plugin->{'=package'};

    eval "require $class; 1" or die;

    $self->plugins->push( $class->new($plugin) );
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
