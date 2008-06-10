package Dist::Zilla;
# ABSTRACT: distribution builder; installer not included!
use Moose;
use Moose::Autobox;
use MooseX::Types::Path::Class qw(Dir File);
use Moose::Util::TypeConstraints;

use File::Find::Rule;
use Path::Class ();
use Software::License;

use Dist::Zilla::Config;

use Dist::Zilla::File::OnDisk;
use Dist::Zilla::Role::Plugin;

=attr name

The name attribute (which is required) gives the name of the distribution to be
built.  This is usually the name of the distribution's main module, with the
double colons (C<::>) replaced with dashes.  For example: C<Dist-Zilla>.

=cut

has name => (
  is   => 'ro',
  isa  => 'Str',
  required => 1,
);

# XXX: *clearly* this needs to be really much smarter -- rjbs, 2008-06-01
has version => (
  is   => 'rw',
  isa  => 'Str',
  required => 1,
);

has abstract => (
  is   => 'rw',
  isa  => 'Str',
  lazy => 1,
  required => 1,
  default  => sub {
    my ($self) = @_;

    require Dist::Zilla::Util;
    Dist::Zilla::Util->_abstract_from_file($self->main_module->name);
  }
);

has main_module => (
  is   => 'ro',
  isa  => 'Dist::Zilla::Role::File',
  lazy => 1,
  required => 1,
  default  => sub {
    my ($self) = @_;

    my $file = $self->files
             ->grep(sub { $_->name =~ /\.pm$/})
             ->sort(sub { length $_[0]->name <=> length $_[1]->name })
             ->head;
  },
);

has copyright_holder => (
  is   => 'ro',
  isa  => 'Str',
  required => 1,
);

has copyright_year => (
  is   => 'ro',
  isa  => 'Int',
  default => (localtime)[5] + 1900,
);

has _license_class => (is => 'rw');

has license => (
  is   => 'ro',
  isa  => 'Software::License',
  lazy => 1,
  required => 1,
  default  => sub {
    my ($self) = @_;
    my $license_class = $self->_license_class;

    unless ($license_class) {
      require Software::LicenseUtils;
      my @guess = Software::LicenseUtils->guess_license_from_pod(
        $self->main_module->content
      );

      Carp::confess("couldn't make a good guess at license") if @guess != 1;
      $license_class = $guess[0];
    }

    my $license = $license_class->new({
      holder => $self->copyright_holder,
      year   => $self->copyright_year,
    });
  },
);

has authors => (
  is   => 'ro',
  isa  => 'ArrayRef[Str]',
  required => 1,
);

has built_in => (
  is   => 'rw',
  isa  => Dir,
  init_arg  => undef,
);

has plugins => (
  is   => 'ro',
  isa  => 'ArrayRef[Dist::Zilla::Role::Plugin]',
  default => sub { [ ] },
);

has files => (
  is   => 'ro',
  isa  => 'ArrayRef[Dist::Zilla::Role::File]',
  lazy => 1,
  init_arg => undef,
  default  => sub { [] },
);

has root => (
  is   => 'ro',
  isa  => Dir,
  coerce   => 1,
  required => 1,
);

sub prereq {
  my ($self) = @_;

  # XXX: This needs to always include the highest version. -- rjbs, 2008-06-01
  my $prereq = {};
  $prereq = $prereq->merge( $_->prereq )
    for $self->plugins_with(-FixedPrereqs)->flatten;

  return $prereq;
}


=method from_config

  my $zilla = Dist::Zilla->from_config;

This routine returns a new Zilla from the configuration in the current working
directory.

=cut

sub from_config {
  my ($class) = @_;

  my $root = Path::Class::dir('.');

  my $config_file = $root->file('dist.ini');
  my $config = Dist::Zilla::Config->read_file($config_file);

  my $plugins = delete $config->{plugins};

  my $license_name = delete $config->{license} unless ref $config->{license};

  my $self = $class->new($config->merge({ root => $root }));

  if ($license_name) {
    my $license_class = "Software::License::$license_name";
    eval "require $license_class; 1" or die;
    $self->_license_class($license_class);
  }

  for my $plugin (@$plugins) {
    my ($plugin_class, $arg) = @$plugin;
    $self->plugins->push(
      $plugin_class->new( $arg->merge({ zilla => $self }) )
    );
  }

  return $self;
}

=method plugins_with

  my $roles = $zilla->plugins_with( -SomeRole );

This method returns an arrayref containing all the Dist::Zilla object's plugins
that perform a the named role.  If the given role name begins with a dash, the
dash is replaced with "Dist::Zilla::Role::"

=cut

sub plugins_with {
  my ($self, $role) = @_;

  $role =~ s/^-/Dist::Zilla::Role::/;
  my $plugins = $self->plugins->grep(sub { $_->does($role) });

  return $plugins;
}

=method build_in

  $zilla->build_in($root);

This method builds the distribution in the given directory.  If no directory
name is given, it defaults to DistName-Version.  If the distribution has
already been built, an exception will be thrown.

=cut

sub build_in {
  my ($self, $root) = @_;

  Carp::confess("attempted to build " . $self->name . " a second time")
    if $self->built_in;

  $_->before_build for $self->plugins_with(-BeforeBuild)->flatten;

  my $build_root = $self->_prep_build_root($root);

  $_->gather_files    for $self->plugins_with(-FileGatherer)->flatten;
  $_->prune_files     for $self->plugins_with(-FilePruner)->flatten;
  $_->munge_files     for $self->plugins_with(-FileMunger)->flatten;
  $_->setup_installer for $self->plugins_with(-InstallTool)->flatten;

  $self->_check_dupe_files;

  for my $file ($self->files->flatten) {
    $self->_write_out_file($file, $build_root);
  }

  $_->after_build({ build_root => $build_root })
    for $self->plugins_with(-AfterBuild)->flatten;

  $self->built_in($build_root);
}

=method ensure_built_in

  $zilla->ensure_built_in($root);

This method behaves like C<L</build_in>>, but if the dist is already built in
C<$root> (or the default root, if no root is given), no exception is raised.

=cut

sub ensure_built_in {
  my ($self, $root) = @_;

  # $root ||= $self->name . q{-} . $self->version;
  return if $self->built_in and 
    (!$root or ($self->built_in eq $root));

  Carp::croak("dist is already built, but not in $root") if $self->built_in;
  $self->build_in($root);
}

=method build_archive

  $dist->build_archive($root);

This method will ensure that the dist has been built in the given root, and
will then build a tarball of that directory in the current directory.

=cut

sub build_archive {
  my ($self, $root) = @_;
  
  $self->ensure_built_in($root);

  require Archive::Tar;
  my $archive = Archive::Tar->new;
  my $built_in = $self->built_in;
  $archive->add_files( $built_in->file( $_->name ) ) for $self->files->flatten;

  ## no critic
  $archive->write($self->name . q{-} . $self->version . '.tar.gz', 9);
}

sub _check_dupe_files {
  my ($self) = @_;

  my %files_named;
  for my $file ($self->files->flatten) {
    ($files_named{ $file->name} ||= [])->push($file);
  }

  return unless
    my @dupes = grep { $files_named{$_}->length > 1 } keys %files_named;

  for my $name (@dupes) {
    warn "attempt to add $name multiple times; added by: "
       . join('; ', map { $_->added_by } @{ $files_named{ $name } }) . "\n";
  }

  Carp::croak("aborting; duplicate files would be produced");
}

sub _prep_build_root {
  my ($self, $build_root) = @_;

  my $default_name = $self->name . q{-} . $self->version;
  $build_root = Path::Class::dir($build_root || $default_name);

  $build_root->mkpath unless -d $build_root;

  my $dist_root = $self->root;

  $build_root->rmtree if -d $build_root;

  return $build_root;
}

sub _write_out_file {
  my ($self, $file, $build_root) = @_;

  my $file_path = Path::Class::file($file->name);

  my $to_dir = $build_root->subdir( $file_path->dir );
  my $to = $to_dir->file( $file_path->basename );
  $to_dir->mkpath unless -e $to_dir;
  die "not a directory: $to_dir" unless -d $to_dir;

  Carp::croak("attempted to write $to multiple times") if -e $to;

  open my $out_fh, '>', "$to" or die "couldn't open $to to write: $!";
  print { $out_fh } $file->content;
  close $out_fh or die "error closing $to: $!";
}

=method log

  $zilla->log($message);

This method logs the given message.  In the future it will be a more useful and
expressive method.  For now, it just prints the string after tacking on a
newline.

=cut

# XXX: yeah, uh, do something more awesome -- rjbs, 2008-06-01
sub log { ## no critic
  my ($self, $msg) = @_;
  print "$msg\n";
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
__END__
=head1 DESCRIPTION

Dist::Zilla builds distributions of code to be uploaded to the CPAN.  In this
respect, it is like L<ExtUtils::MakeMaker>, L<Module::Build>, or
L<Module::Install>.  Unlike those tools, however, it is not also a system for
installing code that has been downloaded from the CPAN.  Since it's only run by
authors, and is meant to be run on a repository checkout rather than on
published, released code, it can do much more than those tools, and is free to
make much more ludicrous demands in terms of prerequisites.

For more information, see L<Dist::Zilla::Tutorial>.
