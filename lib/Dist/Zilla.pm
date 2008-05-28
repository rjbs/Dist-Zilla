package Dist::Zilla;
use Moose;
use Moose::Autobox;

our $VERSION = '0.001';

use File::Find::Rule;
use Path::Class ();

use Dist::Zilla::Config;

use Dist::Zilla::Role::Plugin;

# XXX: should come from config!
sub name { 'Dist::Zilla' }

has config => (
  is   => 'ro',
  isa  => 'HashRef',
  lazy => 1,
  default => sub { Dist::Zilla::Config->read_file('dist.ini') },
);

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
  isa  => 'Path::Class::Dir',
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

  for my $file (map { $dist_root->file($_) } $manifest->flatten) {
    my $to_dir = $build_root->subdir( $file->dir );
    $to_dir->mkpath unless -e $to_dir;
    die "not a directory: $to_dir" unless -d $to_dir;

    my $content = do {
      open my $in_fh, '<', "$file" or die "couldn't open $file to read: $!";
      local $/;
      <$in_fh>;
    };

    my $to = $to_dir->file( $file->basename );
    my $arg = { to => $to, content => $content };
    $_->munge_file($arg) for $self->plugins_with(-FileMunger)->flatten;
    $to = $arg->{to};
  
    open my $out_fh, '>', "$to" or die "couldn't open $to to write: $!";
    print { $out_fh } $arg->{content};
    close $out_fh or die "error closing $to: $!";
  }

  for ($self->plugins_with(-FileWriter)->flatten) {
    $_->write_files({
      build_root => $build_root,
      dist       => $self,
      manifest   => $manifest,
    });
  }

  for ($self->plugins_with(-AfterBuild)->flatten) {
    $_->after_build({
      build_root => $build_root,
      dist       => $self,
      manifest   => $manifest,
    });
  }
}


no Moose;
1;
