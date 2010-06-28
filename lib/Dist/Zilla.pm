package Dist::Zilla;
# ABSTRACT: distribution builder; installer not included!
use Moose 0.92; # role composition fixes
with 'Dist::Zilla::Role::ConfigDumper';

use Moose::Autobox 0.09; # ->flatten
use MooseX::LazyRequire;
use MooseX::Types::Moose qw(ArrayRef Bool HashRef Object Str);
use MooseX::Types::Perl qw(DistName LaxVersionStr);
use MooseX::Types::Path::Class qw(Dir File);
use Moose::Util::TypeConstraints;

use Dist::Zilla::Types qw(License);

use Archive::Tar;
use File::Find::Rule;
use File::pushd ();
use Hash::Merge::Simple ();
use List::MoreUtils qw(uniq);
use List::Util qw(first);
use Log::Dispatchouli 1.100712; # proxy_loggers, quiet_fatal
use Params::Util qw(_HASHLIKE);
use Path::Class;
use Software::License 0.101370; # meta2_name
use String::RewritePrefix;
use Try::Tiny;

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

If you have access to the web, you can learn more and find an interactive
tutorial at B<L<dzil.org|http://dzil.org/>>.  If not, try
L<Dist::Zilla::Tutorial>.

=cut

has chrome => (
  is  => 'rw',
  isa => role_type('Dist::Zilla::Role::Chrome'),
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
  lazy_required => 1,
);

=attr version

This is the version of the distribution to be created.

=cut

has _version_override => (
  isa => LaxVersionStr,
  is  => 'ro' ,
  init_arg => 'version',
);

# XXX: *clearly* this needs to be really much smarter -- rjbs, 2008-06-01
has version => (
  is   => 'rw',
  isa  => LaxVersionStr,
  lazy => 1,
  init_arg  => undef,
  required  => 1,
  builder   => '_build_version',
);

sub _build_version {
  my ($self) = @_;

  my $version = $self->_version_override;

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

has _main_module_override => (
  isa => 'Str',
  is  => 'ro' ,
  init_arg  => 'main_module',
  predicate => '_has_main_module_override',
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

    if ( $self->_has_main_module_override ) {
       $file = first { $_->name eq $self->_main_module_override }
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

=attr license

This is the L<Software::License|Software::License> object for this dist's
license and copyright.

It will be created automatically, if possible, with the
C<copyright_holder> and C<copyright_year> attributes.  If necessary, it will
try to guess the license from the POD of the dist's main module.

A better option is to set the C<license> name in the dist's config to something
understandable, like C<Perl_5>.

=cut

has license => (
  is   => 'ro',
  isa  => License,
  lazy => 1,
  init_arg  => 'license_obj',
  predicate => '_has_license',
  builder   => '_build_license',
  handles   => {
    copyright_holder => 'holder',
    copyright_year   => 'year',
  },
);

sub _build_license {
  my ($self) = @_;

  my $license_class    = $self->_license_class;
  my $copyright_holder = $self->_copyright_holder;
  my $copyright_year   = $self->_copyright_year;

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

    if (@guess != 1) {
      $self->log_fatal(
        "no license data in config, no %Rights stash,",
        "couldn't make a good guess at license from Pod; giving up"
      );
    }

    my $filename = $self->main_module->name;
    $license_class = $guess[0];
    $self->log("based on POD in $filename, guessing license is $guess[0]");
  }

  Class::MOP::load_class($license_class);

  my $license = $license_class->new({
    holder => $self->_copyright_holder,
    year   => $self->_copyright_year,
  });

  $self->_clear_license_class;
  $self->_clear_copyright_holder;
  $self->_clear_copyright_year;

  return $license;
}

has _license_class => (
  is        => 'ro',
  isa       => 'Maybe[Str]',
  lazy      => 1,
  init_arg  => 'license',
  clearer   => '_clear_license_class',
  default   => sub {
    my $stash = $_[0]->stash_named('%Rights');
    $stash && return $stash->license_class;
    return;
  }
);

has _copyright_holder => (
  is        => 'ro',
  isa       => 'Maybe[Str]',
  lazy      => 1,
  init_arg  => 'copyright_holder',
  clearer   => '_clear_copyright_holder',
  default   => sub {
    return unless my $stash = $_[0]->stash_named('%Rights');
    $stash && return $stash->copyright_holder;
    return;
  }
);

has _copyright_year => (
  is        => 'ro',
  isa       => 'Int',
  lazy      => 1,
  init_arg  => 'copyright_year',
  clearer   => '_clear_copyright_year',
  default   => sub {
    # Oh man.  This is a terrible idea!  I mean, what if by the code gets run
    # around like Dec 31, 23:59:59.9 and by the time the default gets called
    # it's the next year but the default was already set up?  Oh man.  That
    # could ruin lives!  I guess we could make this a sub to defer the guess,
    # but think of the performance hit!  I guess we'll have to suffer through
    # this until we can optimize the code to not take .1s to run, right? --
    # rjbs, 2008-06-13
    my $stash = $_[0]->stash_named('%Rights');
    my $year  = $stash && $stash->copyright_year;
    return defined $year ? $year : (localtime)[5] + 1900;
  }
);

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
  isa  => ArrayRef[Str],
  lazy => 1,
  required => 1,
  default  => sub {
    my ($self) = @_;

    if (my $stash  = $self->stash_named('%User')) {
      return $stash->authors;
    }

    my $author = try { $self->copyright_holder };
    return [ $author ] if defined $author and length $author;

    $self->log_fatal(
      "No %User stash and no copyright holder;",
      "can't determine dist author; configure author or a %User section",
    );
  },
);

=attr files

This is an arrayref of objects implementing L<Dist::Zilla::Role::File> that
will, if left in this arrayref, be built into the dist.

Non-core code should avoid altering this arrayref, but sometimes there is not
other way to change the list of files.  In the future, the representation used
for storing files will be changed.

=cut

has files => (
  is   => 'ro',
  isa  => ArrayRef[ role_type('Dist::Zilla::Role::File') ],
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

Non-core code should not alter this arrayref.

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

This is a hashref containing the metadata about this distribution that will be
stored in META.yml or META.json.  You should not alter the metadata in this
hash; use a MetaProvider plugin instead.

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
      version => 2,
      url     => 'http://github.com/dagolden/cpan-meta/',
    },
    name     => $self->name,
    version  => $self->version,
    abstract => $self->abstract,
    author   => $self->authors,
    license  => $self->license->meta2_name,

    # XXX: what about unstable?
    release_status => ($self->is_trial or $self->version =~ /_/)
                    ? 'testing'
                    : 'stable',

    dynamic_config => 0, # problematic, I bet -- rjbs, 2010-06-04
    generated_by   => (ref $self)
                    . ' version '
                    . (defined $self->VERSION ? $self->VERSION : '(undef)')
  };

  $meta = Hash::Merge::Simple::merge($meta, $_->metadata)
    for $self->plugins_with(-MetaProvider)->flatten;

  return $meta;
}

=attr prereqs

This is a L<Dist::Zilla::Prereqs> object, which is a thin layer atop
L<CPAN::Meta::Prereqs>, and describes the distribution's prerequisites.

=cut

has prereqs => (
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

This method should not be relied upon, yet.  Its semantics are likely to
change.

Valid arguments are:

  config_class - the class to use to read the config
                 default: Dist::Zilla::MVP::Reader::Finder

=cut

sub from_config {
  my ($class, $arg) = @_;
  $arg ||= {};

  my $root = dir($arg->{dist_root} || '.');

  my $sequence = $class->_load_config({
    root   => $root,
    chrome => $arg->{chrome},
    config_class    => $arg->{config_class},
    _global_stashes => $arg->{_global_stashes},
  });

  my $self = $sequence->section_named('_')->zilla;

  $self->_setup_default_plugins;

  return $self;
}

sub _setup_default_plugins {
  my ($self) = @_;

  my $infix  = $self->__is_minter ? 'minter' : 'builder';
  my $method = "_setup_default_$infix\_plugins";
  $self->$method;
}

sub _setup_default_minter_plugins {
  my ($self) = @_;

  unless ($self->plugin_named(':DefaultModuleMaker')) {
    require Dist::Zilla::Plugin::TemplateModule;
    my $plugin = Dist::Zilla::Plugin::TemplateModule->new({
      plugin_name => ':DefaultModuleMaker',
      zilla       => $self,
    });

    $self->plugins->push($plugin);
  }
}

sub _setup_default_builder_plugins {
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
        my $map = $self->zilla->_share_dir_map;
        my @files;
        if ( $map->{dist} ) {
          push @files, $self->zilla->files->grep(sub {
            local $_ = $_->name; m{\A\Q$map->{dist}\E/}
          });
        }
        if ( my $mod_map = $map->{module} ) {
          for my $mod ( keys %$mod_map ) {
            push @files, $self->zilla->files->grep(sub {
              local $_ = $_->name; m{\A\Q$mod_map->{$mod}\E/}
            });
          }
        }
        return \@files;
      },
    });

    $self->plugins->push($plugin);
  }
}

sub _load_config {
  my ($class, $arg) = @_;
  $arg ||= {};

  my $config_class =
    $arg->{config_class} ||= 'Dist::Zilla::MVP::Reader::Finder';

  Class::MOP::load_class($config_class);

  $arg->{chrome}->logger->log_debug(
    { prefix => '[DZ] ' },
    "reading configuration using $config_class"
  );

  my $root = $arg->{root};

  require Dist::Zilla::MVP::Assembler::Zilla;
  require Dist::Zilla::MVP::Section;
  my $assembler = Dist::Zilla::MVP::Assembler::Zilla->new({
    chrome        => $arg->{chrome},
    zilla_class   => $class,
    section_class => 'Dist::Zilla::MVP::Section', # make this DZMA default
  });

  for ($assembler->sequence->section_named('_')) {
    $_->add_value(chrome => $arg->{chrome});
    $_->add_value(root   => $arg->{root});
    $_->add_value(_global_stashes => $arg->{_global_stashes})
      if $arg->{_global_stashes};
  }

  my $seq = $config_class->read_config(
    $root->file('dist'),
    {
      assembler => $assembler
    },
  );

  return $seq;
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

has _share_dir_map => (
  is   => 'ro',
  isa  => 'HashRef',
  init_arg  => undef,
  lazy      => 1,
  builder   => '_build_share_dir_map',
);

sub _build_share_dir_map {
  my ($self) = @_;

  my $share_dir_map = {};

  for my $plugin ( $self->plugins_with(-ShareDir)->flatten ) {
    next unless my $sub_map = $plugin->share_dir_map;

    if ( $sub_map->{dist} ) {
      $self->log_fatal("can't install more than one distribution ShareDir")
        if $share_dir_map->{dist};
      $share_dir_map->{dist} = $sub_map->{dist};
    }

    if ( my $mod_map = $sub_map->{module} ) {
      for my $mod ( keys %$mod_map ) {
        $self->log_fatal("can't install more than one ShareDir for $mod")
          if $share_dir_map->{module}{$mod};
        $share_dir_map->{module}{$mod} = $mod_map->{$mod};
      }
    }
  }

  return $share_dir_map;
}

=method build_in

  $zilla->build_in($root);

This method builds the distribution in the given directory.  If no directory
name is given, it defaults to DistName-Version.  If the distribution has
already been built, an exception will be thrown.

=method build

This method just calls C<build_in> with no arguments.  It gets you the default
behavior without the weird-looking formulation of C<build_in> with no object
for the preposition!

=cut

sub build { $_[0]->build_in }

sub build_in {
  my ($self, $root) = @_;

  $self->log_fatal("tried to build with a minter") if $self->__is_minter;

  $self->log_fatal("attempted to build " . $self->name . " a second time")
    if $self->built_in;

  $_->before_build for $self->plugins_with(-BeforeBuild)->flatten;

  $self->log("beginning to build " . $self->name);

  $_->gather_files     for $self->plugins_with(-FileGatherer)->flatten;
  $_->prune_files      for $self->plugins_with(-FilePruner)->flatten;
  $_->munge_files      for $self->plugins_with(-FileMunger)->flatten;

  $_->register_prereqs for $self->plugins_with(-PrereqSource)->flatten;

  $self->prereqs->finalize;

  # Barf if someone has already set up a prereqs entry? -- rjbs, 2010-04-13
  $self->distmeta->{prereqs} = $self->prereqs->as_string_hash;

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

=method ensure_built_in

This method just calls C<ensure_built_in> with no arguments.  It gets you the
default behavior without the weird-looking formulation of C<ensure_built_in>
with no object for the preposition!

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

  $zilla->build_archive;

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

  # Fix up the CHMOD on the archived files, to inhibit 'withoutworldwritables'
  # behaviour on win32.
  for my $f ( $archive->get_files ) {
    $f->mode( $f->mode & ~022 );
  }

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

  # This is needed, or \n is translated to \r\n on win32.
  # Maybe :raw:utf8 is needed, but not sure.
  #     -- Kentnl - 2010-06-10
  binmode( $out_fh , ":raw" );

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

This method removes temporary files and directories suspected to have been
produced by the Dist::Zilla build process.  Specifically, it deletes the
F<.build> directory and any entity that starts with the dist name and a hyphen,
like matching the glob C<Your-Dist-*>.

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

  $zilla->install( \%arg );

This method installs the distribution locally.  The distribution will be built
in a temporary subdirectory, then the process will change directory to that
subdir and an installer will be run.

Valid arguments are:

  install_command - the command to run in the subdir to install the dist
                    default (roughly): $^X -MCPAN -einstall .

                    this argument should be an arrayref

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
            ? @{ $arg->{install_command} }
            : ($^X => '-MCPAN' =>
                $^O eq 'MSWin32' ? q{-e"install '.'"} : '-einstall "."');

    $self->log_debug([ 'installing via %s', \@cmd ]);
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

This method builds a new copy of the distribution and tests it using
C<L</run_tests_in>>.

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

  $zilla->run_in_build( \@cmd );

This method makes a temporary directory, builds the distribution there,
executes the dist's first L<BuildRunner|Dist::Zilla::Role::BuildRunner>, and
then runs the given command in the build directory.  If the command exits
non-zero, the directory will be left in place.

=cut

sub run_in_build {
  my ($self, $cmd) = @_;

  # The sort below is a cheap hack to get ModuleBuild ahead of
  # ExtUtils::MakeMaker. -- rjbs, 2010-01-05
  $self->log_fatal("you can't build without any BuildRunner plugins")
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

=attr logger

This attribute stores a L<Log::Dispatchouli::Proxy> object, used to log
messages.  By default, a proxy to the dist's L<Chrome|Dist::Zilla::Chrome> is
taken.

The following methods are delegated from the Dist::Zilla object to the logger:

=for :list
* log
* log_debug
* log_fatal

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

around dump_config => sub {
  my ($orig, $self) = @_;
  my $config = $self->$orig;
  $config->{is_trial} = $self->is_trial;
  return $config;
};

has _local_stashes => (
  is   => 'ro',
  isa  => HashRef[ Object ],
  lazy => 1,
  default => sub { {} },
);

has _global_stashes => (
  is   => 'ro',
  isa  => HashRef[ Object ],
  lazy => 1,
  default => sub { {} },
);

=method stash_named

  my $stash = $zilla->stash_named( $name );

This method will return the stash with the given name, or undef if none exists.
It looks for a local stash (for this dist) first, then falls back to a global
stash (from the user's global configuration).

=cut

sub stash_named {
  my ($self, $name) = @_;

  return $self->_local_stashes->{ $name } if $self->_local_stashes->{$name};
  return $self->_global_stashes->{ $name };
}

#####################################
## BEGIN DIST MINTING CODE
#####################################

sub _new_from_profile {
  my ($class, $profile_data, $arg) = @_;
  $arg ||= {};

  my $config_class =
    $arg->{config_class} ||= 'Dist::Zilla::MVP::Reader::Finder';
  Class::MOP::load_class($config_class);

  $arg->{chrome}->logger->log_debug(
    { prefix => '[DZ] ' },
    "reading configuration using $config_class"
  );

  require Dist::Zilla::MVP::Assembler::Zilla;
  require Dist::Zilla::MVP::Section;
  my $assembler = Dist::Zilla::MVP::Assembler::Zilla->new({
    chrome        => $arg->{chrome},
    zilla_class   => $class,
    section_class => 'Dist::Zilla::MVP::Section', # make this DZMA default
  });

  for ($assembler->sequence->section_named('_')) {
    $_->add_value(name   => $arg->{name});
    $_->add_value(chrome => $arg->{chrome});
    $_->add_value(__is_minter => 1);
    $_->add_value(_global_stashes => $arg->{_global_stashes})
      if $arg->{_global_stashes};
  }

  my $module = String::RewritePrefix->rewrite(
    { '' => 'Dist::Zilla::MintingProfile::', '=', => '' },
    $profile_data->[0],
  );
  Class::MOP::load_class($module);

  my $profile_dir = $module->profile_dir($profile_data->[1]);

  $assembler->sequence->section_named('_')->add_value(root => $profile_dir);

  my $seq = $config_class->read_config(
    $profile_dir->file('profile'),
    {
      assembler => $assembler
    },
  );

  my $self = $seq->section_named('_')->zilla;

  $self->_setup_default_plugins;

  return $self;
}

# XXX: This is here only because we have not yet broken Zilla into a abstract
# base class with Minter and Builder subclasses. -- rjbs, 2010-05-03
has __is_minter => (
  is  => 'ro',
  isa => Bool,
  default => 0,
);

sub mint_dist {
  my ($self, $arg) = @_;

  $self->log_fatal("tried to mint with a builder") unless $self->__is_minter;

  my $name = $self->name;
  my $dir  = dir($name);
  $self->log_fatal("./$name already exists") if -e $dir;

  $dir = $dir->absolute;

  # XXX: We should have a way to get more than one module name in, and to
  # supply plugin names for the minter to use. -- rjbs, 2010-05-03
  my @modules = do {
    (my $module_name = $name) =~ s/-/::/g;
    ({ name => $module_name });
  };

  $self->log("making directory ./$name");
  $dir->mkpath;

  my $wd = File::pushd::pushd($self->root);

  $_->before_mint  for $self->plugins_with(-BeforeMint)->flatten;

  for my $module (@modules) {
    my $minter = $self->plugin_named(
      $module->{minter_name} || ':DefaultModuleMaker'
    );

    $minter->make_module({ name => $module->{name} })
  }

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

The L<Dist::Zilla website|http://dzil.org/> has several valuable resources for
learning to use Dist::Zilla.

There is a mailing list to discuss Dist::Zilla.  You can L<join the
list|http://www.listbox.com/subscribe/?list_id=139292> or L<browse the
archives|http://listbox.com/member/archive/139292>.

