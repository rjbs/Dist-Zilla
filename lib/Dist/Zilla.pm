package Dist::Zilla;
# ABSTRACT: distribution builder; installer not included!
use Moose 0.92; # role composition fixes
with 'Dist::Zilla::Role::ConfigDumper';

use Moose::Autobox 0.09; # ->flatten
use Dist::Zilla::Types qw(DistName License VersionStr);
use MooseX::Types::Moose qw(Bool HashRef);
use MooseX::Types::Path::Class qw(Dir File);
use Moose::Util::TypeConstraints;

use Archive::Tar;
use File::Find::Rule;
use File::pushd ();
use Hash::Merge::Simple ();
use List::MoreUtils qw(uniq);
use List::Util qw(first);
use Log::Dispatchouli 1.100712; # proxy_loggers, quiet_fatal
use Params::Util qw(_HASHLIKE);
use Path::Class;
use Software::License;
use String::RewritePrefix;

use Dist::Zilla::Prereqs;
use Dist::Zilla::File::OnDisk;
use Dist::Zilla::Role::Plugin;
use Dist::Zilla::Util;

use namespace::autoclean;

=head1 DESCRIPTION

Dist::Zilla builds distributions of code to be uploaded to the CPAN.  In this
respect, it is like L<ExtUtils::MakeMaker>, L<Module::Build>, or
L<Module::Install>.  Unlike those tools, however, it is not also a system for
installing code that has been downloaded from the CPAN.  Since it's only run by
authors, and is meant to be run on a repository checkout rather than on
published, released code, it can do much more than those tools, and is free to
make much more ludicrous demands in terms of prerequisites.

For more information, see L<Dist::Zilla::Tutorial>.

=cut

has chrome => (
  is  => 'rw',
  isa => 'Object', # will be does => 'Dist::Zilla::Role::Chrome' when it exists
  required => 1,
);

=attr name

The name attribute (which is required) gives the name of the distribution to be
built.  This is usually the name of the distribution's main module, with the
double colons (C<::>) replaced with dashes.  For example: C<Dist-Zilla>.

=cut

has name => (
  is   => 'ro',
  isa  => DistName,
  required => 1,
);

=attr version

This is the version of the distribution to be created.

=cut

has version_override => (
  isa => 'Str',
  is  => 'ro' ,
  init_arg => 'version',
);

# XXX: *clearly* this needs to be really much smarter -- rjbs, 2008-06-01
has version => (
  is   => 'rw',
  isa  => VersionStr,
  lazy => 1,
  init_arg  => undef,
  required  => 1,
  builder   => '_build_version',
);

sub _build_version {
  my ($self) = @_;

  my $version = $self->version_override;

  for my $plugin ($self->plugins_with(-VersionProvider)->flatten) {
    next unless defined(my $this_version = $plugin->provide_version);

    $self->log_fatal('attempted to set version twice') if defined $version;

    $version = $this_version;
  }

  $self->log_fatal('no version was ever set') unless defined $version;

  $version;
}

=attr abstract

This is a one-line summary of the distribution.  If none is given, one will be
looked for in the L</main_module> of the dist.

=cut

has abstract => (
  is   => 'rw',
  isa  => 'Str',
  lazy => 1,
  required => 1,
  default  => sub {
    my ($self) = @_;

    unless ($self->main_module) {
      die "no abstract given and no main_module found; make sure your main module is in ./lib\n";
    }

    my $filename = $self->main_module->name;
    $self->log("extracting distribution abstract from $filename");
    my $abstract = Dist::Zilla::Util->abstract_from_file($filename);

    if (!defined($abstract)) {
        die "Unable to extract an abstract from $filename. Please add the following comment to the file with your abstract:
    # ABSTRACT: turns baubles into trinkets
";
    }

    return $abstract;
  }
);

=attr main_module

This is the module where Dist::Zilla might look for various defaults, like
the distribution abstract.  By default, it's derived from the distribution
name.  If your distribution is Foo-Bar, and F<lib/Foo/Bar.pm> exists,
that's the main_module.  Otherwise, it's the shortest-named module in the
distribution.  This may change!

You can override the default by specifying the file path explicitly,
ie:
    main_module = lib/Foo/Bar.pm

=cut

has main_module_override => (
  isa => 'Str',
  is  => 'ro' ,
  init_arg => 'main_module',
  predicate => 'has_main_module_override',
);

has main_module => (
  is   => 'ro',
  isa  => 'Dist::Zilla::Role::File',
  lazy => 1,
  init_arg => undef,
  required => 1,
  default  => sub {

    my ($self) = @_;

    my $file;
    my $guessing = q{};

    if ( $self->has_main_module_override ) {
       $file = first { $_->name eq $self->main_module_override }
               $self->files->flatten;
    } else {
       $guessing = 'guessing '; # We're having to guess

       (my $guess = $self->name) =~ s{-}{/}g;
       $guess = "lib/$guess.pm";

       $file = (first { $_->name eq $guess } $self->files->flatten)
           ||  $self->files
             ->grep(sub { $_->name =~ m{\.pm\z} and $_->name =~ m{\Alib/} })
             ->sort(sub { length $_[0]->name <=> length $_[1]->name })
             ->head;
    }

    $self->log_fatal("Unable to find main_module in dist") unless $file;

    $self->log("${guessing}dist's main_module is " . $file->name);

    return $file;
  },
);

=attr copyright_holder

This is the name of the legal entity who holds the copyright on this code.
This is a required attribute with no default!

=cut

has copyright_holder => (
  is   => 'ro',
  isa  => 'Str',
  required => 1,
);

=attr copyright_year

This is the year of copyright for the dist.  By default, it's this year.

=cut

has copyright_year => (
  is   => 'ro',
  isa  => 'Int',

  # Oh man.  This is a terrible idea!  I mean, what if by the code gets run
  # around like Dec 31, 23:59:59.9 and by the time the default gets called it's
  # the next year but the default was already set up?  Oh man.  That could ruin
  # lives!  I guess we could make this a sub to defer the guess, but think of
  # the performance hit!  I guess we'll have to suffer through this until we
  # can optimize the code to not take .1s to run, right? -- rjbs, 2008-06-13
  default => (localtime)[5] + 1900,
);

=attr license

This is the L<Software::License|Software::License> object for this dist's
license.  It will be created automatically, if possible, with the
C<copyright_holder> and C<copyright_year> attributes.  If necessary, it will
try to guess the license from the POD of the dist's main module.

A better option is to set the C<license> name in the dist's config to something
understandable, like C<Perl_5>.

=cut

has license => (
  reader => 'license',
  writer => '_set_license',
  isa    => License,
  init_arg => undef,
);

sub _initialize_license {
  my ($self, $value) = @_;

  my $license;

  # If it's an object (weird!) we're being handed a pre-created license and
  # we should probably just trust it. -- rjbs, 2009-07-21
  $license = $value if blessed $value;

  unless ($license) {
    my $license_class = $value;

    if ($license_class) {
      $license_class = String::RewritePrefix->rewrite(
        {
          '=' => '',
          ''  => 'Software::License::'
        },
        $license_class,
      );
    } else {
      require Software::LicenseUtils;
      my @guess = Software::LicenseUtils->guess_license_from_pod(
        $self->main_module->content
      );

      $self->log_fatal("couldn't make a good guess at license") if @guess != 1;

      my $filename = $self->main_module->name;
      $license_class = $guess[0];
      $self->log("based on POD in $filename, guessing license is $guess[0]");
    }

    eval "require $license_class; 1" or die;

    $license = $license_class->new({
      holder => $self->copyright_holder,
      year   => $self->copyright_year,
    });
  }

  $self->log_fatal("$value is not a valid license")
    if ! License->check($license);

  $self->_set_license($license);
}

=attr authors

This is an arrayref of author strings, like this:

  [
    'Ricardo Signes <rjbs@cpan.org>',
    'X. Ample, Jr <example@example.biz>',
  ]

This is likely to change at some point in the near future.

=cut

has authors => (
  is   => 'ro',
  isa  => 'ArrayRef[Str]',
  lazy => 1,
  required => 1,
  default  => sub { [ $_[0]->copyright_holder ] },
);

=attr files

This is an arrayref of objects implementing L<Dist::Zilla::Role::File> that
will, if left in this arrayref, be built into the dist.

=cut

has files => (
  is   => 'ro',
  isa  => 'ArrayRef[Dist::Zilla::Role::File]',
  lazy => 1,
  init_arg => undef,
  default  => sub { [] },
);

=attr root

This is the root directory of the dist, as a L<Path::Class::Dir>.  It will
nearly always be the current working directory in which C<dzil> was run.

=cut

has root => (
  is   => 'ro',
  isa  => Dir,
  coerce   => 1,
  required => 1,
);

=attr is_trial

This attribute tells us whether or not the dist will be a trial release.

=cut

has is_trial => (
  is => 'rw', # XXX: make SetOnce -- rjbs, 2010-03-23
  isa => Bool,
  default => sub { $ENV{TRIAL} ? 1 : 0 }
);

=attr plugins

This is an arrayref of plugins that have been plugged into this Dist::Zilla
object.

=cut

has plugins => (
  is   => 'ro',
  isa  => 'ArrayRef[Dist::Zilla::Role::Plugin]',
  init_arg => undef,
  default  => sub { [ ] },
);

=attr built_in

This is the L<Path::Class::Dir>, if any, in which the dist has been built.

=cut

has built_in => (
  is   => 'rw',
  isa  => Dir,
  init_arg  => undef,
);

=attr distmeta

This is a hashref containing the metadata about this distribution that
will be stored in META.yml or META.json.  You should not alter the
metadata in this hash; use a MetaProvider plugin instead.

=cut

has distmeta => (
  is   => 'ro',
  isa  => 'HashRef',
  init_arg  => undef,
  lazy      => 1,
  builder   => '_build_distmeta',
);

sub _build_distmeta {
  my ($self) = @_;

  my $meta = {
    'meta-spec' => {
      version => 1.4,
      url     => 'http://module-build.sourceforge.net/META-spec-v1.4.html',
    },
    name     => $self->name,
    version  => $self->version,
    abstract => $self->abstract,
    author   => $self->authors,
    license  => $self->license->meta_yml_name,
    generated_by => (ref $self)
                  . ' version '
                  . (defined $self->VERSION ? $self->VERSION : '(undef)')
  };

  $meta = Hash::Merge::Simple::merge($meta, $_->metadata)
    for $self->plugins_with(-MetaProvider)->flatten;

  return $meta;
}

=attr prereq

This is a hashref of module prerequisites.  This attribute is likely to get
greatly overhauled, or possibly replaced with a method based on other
(private?) attributes.

I<Actually>, it is more likely that this attribute will contain an object in
the future.

=cut

has prereq => (
  is   => 'ro',
  isa  => 'Dist::Zilla::Prereqs',
  init_arg => undef,
  default  => sub { Dist::Zilla::Prereqs->new },
  handles  => [ qw(register_prereqs) ],
);

=method from_config

  my $zilla = Dist::Zilla->from_config(\%arg);

This routine returns a new Zilla from the configuration in the current working
directory.

Valid arguments are:

  config_class - the class to use to read the config
                 default: Dist::Zilla::Config::Finder

=cut

sub from_config {
  my ($class, $arg) = @_;
  $arg ||= {};

  my $root = dir($arg->{dist_root} || '.');

  my ($seq) = $class->_load_config({
    root   => $root,
    chrome => $arg->{chrome},
    config_class => $arg->{config_class},
  });

  my $core_config = $seq->section_named('_')->payload;

  my $self = $class->new({
    %$core_config,
    chrome => $arg->{chrome},
  });

  for my $section ($seq->sections) {
    next if $section->name eq '_';

    my ($name, $plugin_class, $arg) = (
      $section->name,
      $section->package,
      $section->payload,
    );

    $self->log_fatal("$name arguments attempted to override plugin name")
      if defined $arg->{plugin_name};

    $self->log_fatal("$name arguments attempted to override plugin name")
      if defined $arg->{zilla};

    my $plugin = $plugin_class->new(
      $arg->merge({
        plugin_name => $name,
        zilla       => $self,
      }),
    );

    my $version = $plugin->VERSION || 0;

    $plugin->log_debug([ 'online, %s v%s', $plugin->meta->name, $version ]);

    $self->plugins->push($plugin);
  }

  $self->_setup_default_plugins;

  return $self;
}

sub _setup_default_plugins {
  my ($self) = @_;

  unless ($self->plugin_named(':InstallModules')) {
    require Dist::Zilla::Plugin::FinderCode;
    my $plugin = Dist::Zilla::Plugin::FinderCode->new({
      plugin_name => ':InstallModules',
      zilla       => $self,
      style       => 'grep',
      code        => sub { local $_ = $_->name; m{\Alib/} and m{\.(pm|pod)$} },
    });

    $self->plugins->push($plugin);
  }

  unless ($self->plugin_named(':TestFiles')) {
    require Dist::Zilla::Plugin::FinderCode;
    my $plugin = Dist::Zilla::Plugin::FinderCode->new({
      plugin_name => ':TestFiles',
      zilla       => $self,
      style       => 'grep',
      code        => sub { local $_ = $_->name; m{\At/} },
    });

    $self->plugins->push($plugin);
  }

  unless ($self->plugin_named(':ExecFiles')) {
    require Dist::Zilla::Plugin::FinderCode;
    my $plugin = Dist::Zilla::Plugin::FinderCode->new({
      plugin_name => ':ExecFiles',
      zilla       => $self,
      style       => 'list',
      code        => sub {
        my $plugins = $_[0]->zilla->plugins_with(-ExecFiles);
        my @files = map {; @{ $_->find_files } } @$plugins;

        return \@files;
      },
    });

    $self->plugins->push($plugin);
  }

  unless ($self->plugin_named(':ShareFiles')) {
    require Dist::Zilla::Plugin::FinderCode;
    my $plugin = Dist::Zilla::Plugin::FinderCode->new({
      plugin_name => ':ShareFiles',
      zilla       => $self,
      style       => 'list',
      code        => sub {
        return [] unless my $dir = $self->zilla->_share_dir;
        return $self->zilla->files->grep(sub {
          local $_ = $_->name; m{\A\Q$dir\E/}
        });
      },
    });

    $self->plugins->push($plugin);
  }
}

sub _load_config {
  my ($self, $arg) = @_;
  $arg ||= {};

  my $config_class = $arg->{config_class} ||= 'Dist::Zilla::Config::Finder';
  Class::MOP::load_class($config_class);

  $arg->{chrome}->logger->log_debug(
    { prefix => '[DZ] ' },
    "reading configuration using $config_class"
  );

  my $root = $arg->{root};
  my ($sequence) = $config_class->new->read_config({
    root     => $root,
    basename => 'dist',
  });

  # I wonder if the root should be named '' or something, but that's probably
  # sort of a ridiculous thing to worry about. -- rjbs, 2009-08-24
  $sequence->section_named('_')->add_value(root => $root);

  return $sequence;
}

=method plugin_named

  my $plugin = $zilla->plugin_named( $plugin_name );

=cut

sub plugin_named {
  my ($self, $name) = @_;
  my $plugin = first { $_->plugin_name eq $name } $self->plugins->flatten;

  return $plugin if $plugin;
  return;
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

=method find_files

  my $files = $zilla->find_files( $finder_name );

This method will look for a
L<FileFinder|Dist::Zilla::Role::FileFinder>-performing plugin with the given
name and return the result of calling C<find_files> on it.  If no plugin can be
found, an exception will be raised.

=cut

sub find_files {
  my ($self, $finder_name) = @_;

  $self->log_fatal("no plugin named $finder_name found")
    unless my $plugin = $self->plugin_named($finder_name);

  $self->log_fatal("plugin $finder_name is not a FileFinder")
    unless $plugin->does('Dist::Zilla::Role::FileFinder');

  $plugin->find_files;
}

sub _share_dir {
  my ($self) = @_;

  my @share_dirs =
    uniq $self->plugins_with(-ShareDir)->map(sub { $_->dir })->flatten;

  $self->log_fatal("can't install more than one ShareDir") if @share_dirs > 1;

  return unless defined(my $share_dir = $share_dirs[0]);

  return unless grep { $_->name =~ m{\A\Q$share_dir\E/} }
                $self->files->flatten;

  return $share_dirs[0];
}

=method build_in

  $zilla->build_in($root);

This method builds the distribution in the given directory.  If no directory
name is given, it defaults to DistName-Version.  If the distribution has
already been built, an exception will be thrown.

=method build

This method just calls C<build_in> with no arguments.  It get you the default
behavior without the weird-looking formulation of C<build_in> with no object
for the preposition!

=cut

sub build { $_[0]->build_in }

sub build_in {
  my ($self, $root) = @_;

  $self->log_fatal("attempted to build " . $self->name . " a second time")
    if $self->built_in;

  $_->before_build for $self->plugins_with(-BeforeBuild)->flatten;

  $self->log("beginning to build " . $self->name);

  $_->gather_files     for $self->plugins_with(-FileGatherer)->flatten;
  $_->prune_files      for $self->plugins_with(-FilePruner)->flatten;
  $_->munge_files      for $self->plugins_with(-FileMunger)->flatten;

  $_->register_prereqs for $self->plugins_with(-PrereqSource)->flatten;

  $self->prereq->finalize;

  my $meta   = $self->distmeta;
  my $prereq = $self->prereq->as_distmeta;
  $meta->{ $_ } = $prereq->{ $_ } for keys %$prereq;

  $_->setup_installer for $self->plugins_with(-InstallTool)->flatten;

  $self->_check_dupe_files;

  my $build_root = $self->_prep_build_root($root);

  $self->log("writing " . $self->name . " in $build_root");

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

sub ensure_built {
  $_[0]->ensure_built_in;
}

sub ensure_built_in {
  my ($self, $root) = @_;

  # $root ||= $self->name . q{-} . $self->version;
  return $self->built_in if $self->built_in and
    (!$root or ($self->built_in eq $root));

  Carp::croak("dist is already built, but not in $root") if $self->built_in;
  $self->build_in($root);
}

=method build_archive

  $dist->build_archive;

This method will ensure that the dist has been built, and will then build a
tarball of the build directory in the current directory.

=cut

sub build_archive {
  my ($self, $file) = @_;

  my $built_in = $self->ensure_built;

  my $archive = Archive::Tar->new;

  $_->before_archive for $self->plugins_with(-BeforeArchive)->flatten;

  my %seen_dir;
  for my $distfile ($self->files->flatten) {
    my $in = file($distfile->name)->dir;
    $archive->add_files( $built_in->subdir($in) ) unless $seen_dir{ $in }++;
    $archive->add_files( $built_in->file( $distfile->name ) );
  }

  ## no critic
  $file ||= file(join(q{},
    $self->name,
    '-',
    $self->version,
    ($self->is_trial ? '-TRIAL' : ''),
    '.tar.gz',
  ));

  $self->log("writing archive to $file");
  $archive->write("$file", 9);

  return $file;
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
    $self->log("attempt to add $name multiple times; added by: "
       . join('; ', map { $_->added_by } @{ $files_named{ $name } })
    );
  }

  Carp::croak("aborting; duplicate files would be produced");
}

sub _prep_build_root {
  my ($self, $build_root) = @_;

  my $default_name = $self->name . q{-} . $self->version;
  $build_root = dir($build_root || $default_name);

  $build_root->mkpath unless -d $build_root;

  my $dist_root = $self->root;

  $build_root->rmtree if -d $build_root;

  return $build_root;
}

sub _write_out_file {
  my ($self, $file, $build_root) = @_;

  # Okay, this is a bit much, until we have ->debug. -- rjbs, 2008-06-13
  # $self->log("writing out " . $file->name);

  my $file_path = file($file->name);

  my $to_dir = $build_root->subdir( $file_path->dir );
  my $to = $to_dir->file( $file_path->basename );
  $to_dir->mkpath unless -e $to_dir;
  die "not a directory: $to_dir" unless -d $to_dir;

  Carp::croak("attempted to write $to multiple times") if -e $to;

  open my $out_fh, '>', "$to" or die "couldn't open $to to write: $!";
  print { $out_fh } $file->content;
  close $out_fh or die "error closing $to: $!";
  chmod $file->mode, "$to" or die "couldn't chmod $to: $!";
}

=method release

  $zilla->release;

This method releases the distribution, probably by uploading it to the CPAN.
The actual effects of this method (as with most of the methods) is determined
by the loaded plugins.

=cut

sub release {
  my $self = shift;

  Carp::croak("you can't release without any Releaser plugins")
    unless my @releasers = $self->plugins_with(-Releaser)->flatten;

  my $tgz = $self->build_archive;

  # call all plugins implementing BeforeRelease role
  $_->before_release($tgz) for $self->plugins_with(-BeforeRelease)->flatten;

  # do the actual release
  $_->release($tgz) for @releasers;

  # call all plugins implementing AfterRelease role
  $_->after_release($tgz) for $self->plugins_with(-AfterRelease)->flatten;
}

=method clean

=cut

sub clean {
  my ($self) = @_;

  require File::Path;
  for my $x (grep { -e } '.build', glob($self->name . '-*')) {
    $self->log("clean: removing $x");
    File::Path::rmtree($x);
  };
}

=method install

=cut

sub install {
  my ($self, $arg) = @_;
  $arg ||= {};

  require File::Temp;

  my $build_root = dir('.build');
  $build_root->mkpath unless -d $build_root;

  my $target = dir( File::Temp::tempdir(DIR => $build_root) );
  $self->log("building distribution under $target for installation");
  $self->ensure_built_in($target);

  eval {
    ## no critic Punctuation
    my $wd = File::pushd::pushd($target);
    my @cmd = $arg->{install_command}
            ? $arg->{install_command}
            : ($^X => '-MCPAN' => '-einstall "."');

    system(@cmd) && $self->log_fatal([ "error running %s", \@cmd ]);
  };

  if ($@) {
    $self->log($@);
    $self->log("left failed dist in place at $target");
  } else {
    $self->log("all's well; removing $target");
    $target->rmtree;
  }

  return;
}

=method test

  $zilla->test;

This method builds a new copy of the distribution and tests it.

=cut

sub test {
  my ($self) = @_;

  Carp::croak("you can't test without any TestRunner plugins")
    unless my @testers = $self->plugins_with(-TestRunner)->flatten;

  require File::Temp;

  my $build_root = dir('.build');
  $build_root->mkpath unless -d $build_root;

  my $target = dir( File::Temp::tempdir(DIR => $build_root) );
  $self->log("building test distribution under $target");

  local $ENV{AUTHOR_TESTING} = 1;
  local $ENV{RELEASE_TESTING} = 1;

  $self->ensure_built_in($target);

  my $error = $self->run_tests_in($target);

  $self->log("all's well; removing $target");
  $target->rmtree;
}

=method run_tests_in

  my $error = $zilla->run_tests_in($directory);

This method runs the tests in $directory (a Path::Class::Dir), which
must contain an already-built copy of the distribution.  It will throw an
exception if there are test failures.

It does I<not> set any of the C<*_TESTING> environment variables, nor
does it clean up C<$directory> afterwards.

=cut

sub run_tests_in {
  my ($self, $target) = @_;

  Carp::croak("you can't test without any TestRunner plugins")
    unless my @testers = $self->plugins_with(-TestRunner)->flatten;

  for my $tester (@testers) {
    my $wd = File::pushd::pushd($target);
    $tester->test( $target );
  }
}

=method run_in_build

=cut

sub run_in_build {
  my ($self, $cmd) = @_;

  # The sort below is a cheap hack to get ModuleBuild ahead of
  # ExtUtils::MakeMaker. -- rjbs, 2010-01-05
  Carp::croak("you can't build without any BuildRunner plugins")
    unless my @builders =
    $self->plugins_with(-BuildRunner)->sort->reverse->flatten;

  require "Config.pm"; # skip autoprereq
  require File::Temp;

  # dzil-build the dist
  my $build_root = dir('.build');
  $build_root->mkpath unless -d $build_root;

  my $target    = dir( File::Temp::tempdir(DIR => $build_root) );
  my $abstarget = $target->absolute;
  $self->log("building test distribution under $target");

  $self->ensure_built_in($target);

  # building the dist for real
  my $ok = eval {
    my $wd = File::pushd::pushd($target);
    $builders[0]->build;
    local $ENV{PERL5LIB} =
      join $Config::Config{path_sep},
      map { $abstarget->subdir('blib', $_) } qw{ arch lib };
    system(@$cmd) and die "error while running: @$cmd";
    1;
  };

  if ($ok) {
    $self->log("all's well; removing $target");
    $target->rmtree;
  } else {
    my $error = $@ || '(unknown error)';
    $self->log($error);
    $self->log_fatal("left failed dist in place at $target");
  }
}

=method log

  $zilla->log($message);

This method logs the given message.

=cut

has logger => (
  is   => 'ro',
  isa  => 'Log::Dispatchouli::Proxy', # could be duck typed, I guess
  lazy => 1,
  handles => [ qw(log log_debug log_fatal) ],
  default => sub {
    $_[0]->chrome->logger->proxy({ proxy_prefix => '[DZ] ' })
  },
);

sub BUILD {
  my ($self, $arg) = @_;

  $self->_initialize_license($arg->{license});
}

around dump_config => sub {
  my ($orig, $self) = @_;
  my $config = $self->$orig;
  $config->{is_trial} = $self->is_trial;
  return $config;
};

sub _global_config {
  my ($self) = @_;

  my $homedir = File::HomeDir->my_home
    or Carp::croak("couldn't determine home directory");

  my $file = dir($homedir)->file('.dzil');
  return unless -e $file;

  if (-d $file) {
    return Dist::Zilla::Config::Finder->new->read_config({
      root     =>  dir($homedir)->subdir('.dzil'),
      basename => 'config',
    });
  } else {
    return Dist::Zilla::Config::Finder->new->read_config({
      root     => dir($homedir),
      filename => '.dzil',
    });
  }
}

sub _global_config_for {
  my ($self, $plugin_class) = @_;

  return {} unless my $global_config = $self->_global_config;

  my ($section) = grep { ($_->package||'') eq $plugin_class }
                  $global_config->sections;

  return {} unless $section;

  return $section->payload;
}

#####################################
## BEGIN DIST MINTING CODE
#####################################

sub _new_from_profile {
  my ($class, $profile_name, $arg) = @_;
  $arg ||= {};

  my $config_class = $arg->{config_class} ||= 'Dist::Zilla::Config::Finder';
  Class::MOP::load_class($config_class);

  $arg->{chrome}->logger->log_debug(
    { prefix => '[DZ] ' },
    "reading configuration using $config_class"
  );

  my $profile_dir = dir( File::HomeDir->my_home )->subdir(qw(.dzil profiles));

  my $sequence;

  if ($profile_name eq 'default' and ! -e $profile_dir->subdir('default')) {
    ...
  } else {
    ($sequence) = $config_class->new->read_config({
      root     => $profile_dir->subdir($profile_name),
      basename => 'profile',
    });
  }

  my $self = $class->new({
    %{ $sequence->section_named('_')->payload },
    name   => $arg->{name},
    chrome => $arg->{chrome},
    root   => $profile_dir->subdir($profile_name),
  });

  for my $section ($sequence->sections) {
    next if $section->name eq '_';

    my ($name, $plugin_class, $arg) = (
      $section->name,
      $section->package,
      $section->payload,
    );

    $self->log_fatal("$name arguments attempted to override plugin name")
      if defined $arg->{plugin_name};

    $self->log_fatal("$name arguments attempted to override plugin name")
      if defined $arg->{zilla};

    my $plugin = $plugin_class->new(
      $arg->merge({
        plugin_name => $name,
        zilla       => $self,
      }),
    );

    my $version = $plugin->VERSION || 0;

    $plugin->log_debug([ 'online, %s v%s', $plugin->meta->name, $version ]);

    $self->plugins->push($plugin);
  }

  return $self;
}

sub mint_dist {
  my ($self, $arg) = @_;

  my $name = $arg->{name};
  my $dir  = dir($name);
  $self->log_fatal("./$name already exists") if -e $dir;

  $dir = $dir->absolute;

  $self->log("making directory ./$name");
  $dir->mkpath;

  my $wd = File::pushd::pushd($self->root);

  $_->before_mint  for $self->plugins_with(-BeforeMint)->flatten;
  $_->gather_files for $self->plugins_with(-FileGatherer)->flatten;
  $_->prune_files  for $self->plugins_with(-FilePruner)->flatten;
  $_->munge_files  for $self->plugins_with(-FileMunger)->flatten;

  $self->_check_dupe_files;

  $self->log("writing files to $dir");

  for my $file ($self->files->flatten) {
    $self->_write_out_file($file, $dir);
  }

  $_->after_mint({ mint_root => $dir })
    for $self->plugins_with(-AfterMint)->flatten;

  $self->log("dist minted in ./$name");
}

#####################################
## END DIST MINTING CODE
#####################################

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 SUPPORT

There are usually people on C<irc.perl.org> in C<#distzilla>, even if they're
idling.

There is a mailing list to discuss Dist::Zilla.  You can L<join the
list|http://www.listbox.com/subscribe/?list_id=139292> or L<browse the
archives|http://listbox.com/member/archive/139292>.

