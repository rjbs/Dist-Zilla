package Dist::Zilla::Dist::Builder;
# ABSTRACT: dist zilla subclass for building dists

use Moose 0.92; # role composition fixes
extends 'Dist::Zilla';

use MooseX::Types::Moose qw(HashRef);
use MooseX::Types::Path::Class qw(Dir File);

use File::pushd ();
use Path::Class;
use Path::Tiny; # because more Path::* is better, eh?
use Try::Tiny;

use namespace::autoclean;

=method from_config

  my $zilla = Dist::Zilla->from_config(\%arg);

This routine returns a new Zilla from the configuration in the current working
directory.

This method should not be relied upon, yet.  Its semantics are B<certain> to
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
  unless ($self->plugin_named(':InstallModules')) {
    require Dist::Zilla::Plugin::FinderCode;
    my $plugin = Dist::Zilla::Plugin::FinderCode->new({
      plugin_name => ':InstallModules',
      zilla       => $self,
      style       => 'grep',
      code        => sub {
        my ($file, $self) = @_;
        local $_ = $file->name;
        return 1 if m{\Alib/} and m{\.(pm|pod)$};
        return;
      },
    });

    push @{ $self->plugins }, $plugin;
  }

  unless ($self->plugin_named(':IncModules')) {
    require Dist::Zilla::Plugin::FinderCode;
    my $plugin = Dist::Zilla::Plugin::FinderCode->new({
      plugin_name => ':IncModules',
      zilla       => $self,
      style       => 'grep',
      code        => sub {
        my ($file, $self) = @_;
        local $_ = $file->name;
        return 1 if m{\Ainc/} and m{\.pm$};
        return;
      },
    });

    push @{ $self->plugins }, $plugin;
  }

  unless ($self->plugin_named(':TestFiles')) {
    require Dist::Zilla::Plugin::FinderCode;
    my $plugin = Dist::Zilla::Plugin::FinderCode->new({
      plugin_name => ':TestFiles',
      zilla       => $self,
      style       => 'grep',
      code        => sub { local $_ = $_->name; m{\At/} },
    });

    push @{ $self->plugins }, $plugin;
  }

  unless ($self->plugin_named(':ExtraTestFiles')) {
    require Dist::Zilla::Plugin::FinderCode;
    my $plugin = Dist::Zilla::Plugin::FinderCode->new({
      plugin_name => ':ExtraTestFiles',
      zilla       => $self,
      style       => 'grep',
      code        => sub { local $_ = $_->name; m{\Axt/} },
    });

    push @{ $self->plugins }, $plugin;
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

    push @{ $self->plugins }, $plugin;
  }

  unless ($self->plugin_named(':PerlExecFiles')) {
    require Dist::Zilla::Plugin::FinderCode;
    my $plugin = Dist::Zilla::Plugin::FinderCode->new({
      plugin_name => ':PerlExecFiles',
      zilla       => $self,
      style       => 'list',
      code        => sub {
        my $parent_plugin = $self->plugin_named(':ExecFiles');
        my @files = grep {
          $_->name =~ m{\.pl$}
              or $_->content =~ m{^\s*\#\!.*perl\b};
        } @{ $parent_plugin->find_files };
        return \@files;
      },
    });

    push @{ $self->plugins }, $plugin;
  }

  unless ($self->plugin_named(':ShareFiles')) {
    require Dist::Zilla::Plugin::FinderCode;
    my $plugin = Dist::Zilla::Plugin::FinderCode->new({
      plugin_name => ':ShareFiles',
      zilla       => $self,
      style       => 'list',
      code        => sub {
        my $self = shift;
        my $map = $self->zilla->_share_dir_map;
        my @files;
        if ( $map->{dist} ) {
          push @files, grep {; $_->name =~ m{\A\Q$map->{dist}\E/} }
                       @{ $self->zilla->files };
        }
        if ( my $mod_map = $map->{module} ) {
          for my $mod ( keys %$mod_map ) {
            push @files, grep { $_->name =~ m{\A\Q$mod_map->{$mod}\E/} }
                         @{ $self->zilla->files };
          }
        }
        return \@files;
      },
    });

    push @{ $self->plugins }, $plugin;
  }

  unless ($self->plugin_named(':MainModule')) {
    require Dist::Zilla::Plugin::FinderCode;
    my $plugin = Dist::Zilla::Plugin::FinderCode->new({
      plugin_name => ':MainModule',
      zilla       => $self,
      style       => 'grep',
      code        => sub {
        my ($file, $self) = @_;
        local $_ = $file->name;
        return 1 if $_ eq $self->zilla->main_module->name;
        return;
      },
    });

    push @{ $self->plugins }, $plugin;
  }

  unless ($self->plugin_named(':AllFiles')) {
    require Dist::Zilla::Plugin::FinderCode;
    my $plugin = Dist::Zilla::Plugin::FinderCode->new({
      plugin_name => ':AllFiles',
      zilla       => $self,
      style       => 'grep',
      code        => sub { return 1 },
    });

    push @{ $self->plugins }, $plugin;
  }

  unless ($self->plugin_named(':NoFiles')) {
    require Dist::Zilla::Plugin::FinderCode;
    my $plugin = Dist::Zilla::Plugin::FinderCode->new({
      plugin_name => ':NoFiles',
      zilla       => $self,
      style       => 'list',
      code        => sub { return },
    });

    push @{ $self->plugins }, $plugin;
  }
}

has _share_dir_map => (
  is   => 'ro',
  isa  => HashRef,
  init_arg  => undef,
  lazy      => 1,
  builder   => '_build_share_dir_map',
);

sub _build_share_dir_map {
  my ($self) = @_;

  my $share_dir_map = {};

  for my $plugin (@{ $self->plugins_with(-ShareDir) }) {
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


sub _load_config {
  my ($class, $arg) = @_;
  $arg ||= {};

  my $config_class =
    $arg->{config_class} ||= 'Dist::Zilla::MVP::Reader::Finder';

  Class::Load::load_class($config_class);

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

  my $seq;
  try {
    $seq = $config_class->read_config(
      $root->file('dist'),
      {
        assembler => $assembler
      },
    );
  } catch {
    die $_ unless try {
      $_->isa('Config::MVP::Error')
      and $_->ident eq 'package not installed'
    };

    my $package = $_->package;
    my $bundle  = $_->section_name =~ m{^@(?!.*/)} ? ' bundle' : '';

    die <<"END_DIE";
Required plugin$bundle $package isn't installed.

Run 'dzil authordeps' to see a list of all required plugins.
You can pipe the list to your CPAN client to install or update them:

    dzil authordeps --missing | cpanm

END_DIE

  };

  return $seq;
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

  $self->log_fatal("tried to build with a minter")
    if $self->isa('Dist::Zilla::Dist::Minter');

  $self->log_fatal("attempted to build " . $self->name . " a second time")
    if $self->built_in;

  $self->phase('BeforeBuild', 'before_build');

  $self->log("beginning to build " . $self->name);

  $self->phase('FileGatherer', 'gather_files');
  $self->phase('EncodingProvider', 'set_file_encodings');
  $self->phase('FilePruner', 'prune_files' );

  $self->version; # instantiate this lazy attribute now that files are gathered

  $self->phase('FileMunger', 'munge_files');

  $self->phase('PrereqSource', 'register_prereqs');

  $self->prereqs->finalize;

  # Barf if someone has already set up a prereqs entry? -- rjbs, 2010-04-13
  $self->distmeta->{prereqs} = $self->prereqs->as_string_hash;

  $self->phase('InstallTool', 'setup_installer' );

  $self->_check_dupe_files;

  my $build_root = $self->_prep_build_root($root);

  $self->log("writing " . $self->name . " in $build_root");

  for my $file (@{ $self->files }) {
    $self->_write_out_file($file, $build_root);
  }

  $self->phase('AfterBuild', 'after_build', { build_root => $build_root });

  $self->built_in($build_root);
}

=attr built_in

This is the L<Path::Class::Dir>, if any, in which the dist has been built.

=cut

has built_in => (
  is   => 'rw',
  isa  => Dir,
  init_arg  => undef,
);

=method ensure_built_in

  $zilla->ensure_built_in($root);

This method behaves like C<L</build_in>>, but if the dist is already built in
C<$root> (or the default root, if no root is given), no exception is raised.

=method ensure_built

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

=method dist_basename

  my $basename = $zilla->dist_basename;

This method will return the dist's basename (e.g. C<Dist-Name-1.01>.
The basename is used as the top-level directory in the tarball.  It
does not include C<-TRIAL>, even if building a trial dist.

=cut

sub dist_basename {
  my ($self) = @_;
  return join(q{},
    $self->name,
    '-',
    $self->version,
  );
}

=method archive_filename

  my $tarball = $zilla->archive_filename;

This method will return the filename (e.g. C<Dist-Name-1.01.tar.gz>)
of the tarball of this distribution.  It will include C<-TRIAL> if building a
trial distribution, unless the version contains an underscore.  The tarball
might not exist.

=cut

sub archive_filename {
  my ($self) = @_;
  return join(q{},
    $self->dist_basename,
    ( $self->is_trial && $self->version !~ /_/ ? '-TRIAL' : '' ),
    '.tar.gz'
  );
}

=method build_archive

  $zilla->build_archive;

This method will ensure that the dist has been built, and will then build a
tarball of the build directory in the current directory.

=cut

sub build_archive {
  my ($self) = @_;

  my $built_in = $self->ensure_built;

  my $basename = $self->dist_basename;
  my $basedir = dir($basename);

  $self->phase('BeforeArchive', 'before_archive');

  my $method = Class::Load::load_optional_class('Archive::Tar::Wrapper',
                                                { -version => 0.15 })
             ? '_build_archive_with_wrapper'
             : '_build_archive';

  my $archive = $self->$method($built_in, $basename, $basedir);

  my $file = file($self->archive_filename);

  $self->log("writing archive to $file");
  $archive->write("$file", 9);

  return $file;
}

sub _build_archive {
  my ($self, $built_in, $basename, $basedir) = @_;

  $self->log("building archive with Archive::Tar; install Archive::Tar::Wrapper 0.15 or newer for improved speed");

  require Archive::Tar;
  my $archive = Archive::Tar->new;
  my %seen_dir;
  for my $distfile (
    sort { length($a->name) <=> length($b->name) } @{ $self->files }
  ) {
    my $in = file($distfile->name)->dir;

    unless ($seen_dir{ $in }++) {
      $archive->add_data(
        $basedir->subdir($in),
        '',
        { type => Archive::Tar::Constant::DIR(), mode => 0755 },
      )
    }

    my $filename = $built_in->file( $distfile->name );
    $archive->add_data(
      $basedir->file( $distfile->name ),
      path($filename)->slurp_raw,
      { mode => (stat $filename)[2] & ~022 },
    );
  }

  return $archive;
}

sub _build_archive_with_wrapper {
  my ($self, $built_in, $basename, $basedir) = @_;

  $self->log("building archive with Archive::Tar::Wrapper");

  my $archive = Archive::Tar::Wrapper->new;

  for my $distfile (
    sort { length($a->name) <=> length($b->name) } @{ $self->files }
  ) {
    my $in = file($distfile->name)->dir;

    my $filename = $built_in->file( $distfile->name );
    $archive->add(
      $basedir->file( $distfile->name )->stringify,
      $filename->stringify,
      { perm => (stat $filename)[2] & ~022 },
    );
  }

  return $archive;
}

sub _prep_build_root {
  my ($self, $build_root) = @_;

  $build_root = dir($build_root || $self->dist_basename);

  $build_root->mkpath unless -d $build_root;

  my $dist_root = $self->root;

  return $build_root if !-d $build_root;

  my $res = $build_root->rmtree; # this warns with error details
  die "unable to delete '$build_root' in preparation of build" if !$res;

  # the following is done only on windows, and only if the deletion failed,
  # yet rmtree reported success, because currently rmdir is non-blocking as per:
  # https://rt.perl.org/Ticket/Display.html?id=123958
  if ( $^O eq 'MSWin32' and -d $build_root ) {
    $self->log("spinning for at least one second to allow other processes to release locks on $build_root");
    my $timeout = time + 2;
    while(time != $timeout and -d $build_root) { }
    die "unable to delete '$build_root' in preparation of build because some process has a lock on it"
      if -d $build_root;
  }

  return $build_root;
}

=method release

  $zilla->release;

This method releases the distribution, probably by uploading it to the CPAN.
The actual effects of this method (as with most of the methods) is determined
by the loaded plugins.

=cut

sub release {
  my $self = shift;

  $self->log_fatal("you can't release without any Releaser plugins")
    unless @{ $self->plugins_with(-Releaser) };
    # VDB: Is it important to abort before 'before_ewlease'?
    # Could it be moved after 'before_release'?

  $ENV{DZIL_RELEASING} = 1;

  my $tgz = $self->build_archive;

  # call all plugins implementing BeforeRelease role
  $self->phase('BeforeRelease', 'before_release', $tgz);

  # do the actual release
  $self->phase('Releaser', 'release', $tgz);

  # call all plugins implementing AfterRelease role
  $self->phase('AfterRelease', 'after_release', $tgz);
}

=method clean

This method removes temporary files and directories suspected to have been
produced by the Dist::Zilla build process.  Specifically, it deletes the
F<.build> directory and any entity that starts with the dist name and a hyphen,
like matching the glob C<Your-Dist-*>.

=cut

sub clean {
  my ($self, $dry_run) = @_;

  require File::Path;
  for my $x (grep { -e } '.build', glob($self->name . '-*')) {
    if ($dry_run) {
      $self->log("clean: would remove $x");
    } else {
      $self->log("clean: removing $x");
      File::Path::rmtree($x);
    }
  };
}

=method ensure_built_in_tmpdir

  $zilla->ensure_built_in_tmpdir;

This method will consistently build the distribution in a temporary
subdirectory. It will return the path for the temporary build location.

=cut

sub ensure_built_in_tmpdir {
  my $self = shift;

  require File::Temp;

  my $build_root = dir('.build');
  $build_root->mkpath unless -d $build_root;

  my $target = dir( File::Temp::tempdir(DIR => $build_root) );
  $self->log("building distribution under $target for installation");

  my $os_has_symlinks = eval { symlink("",""); 1 };
  my $previous;
  my $latest;

  if( $os_has_symlinks ) {
    $previous = file( $build_root, 'previous' );
    $latest   = file( $build_root, 'latest'   );
    if( -l $previous ) {
      $previous->remove
        or $self->log("cannot remove old .build/previous link");
    }
    if( -l $latest ) {
      rename $latest, $previous
        or $self->log("cannot move .build/latest link to .build/previous");
    }
    symlink $target->basename, $latest
      or $self->log('cannot create link .build/latest');
  }

  $self->ensure_built_in($target);

  return ($target, $latest, $previous);
}

=method install

  $zilla->install( \%arg );

This method installs the distribution locally.  The distribution will be built
in a temporary subdirectory, then the process will change directory to that
subdir and an installer will be run.

Valid arguments are:

  keep_build_dir  - if true, don't rmtree the build dir, even if everything
                    seemed to work
  install_command - the command to run in the subdir to install the dist
                    default (roughly): $^X -MCPAN -einstall .

                    this argument should be an arrayref

=cut

sub install {
  my ($self, $arg) = @_;
  $arg ||= {};

  my ($target, $latest) = $self->ensure_built_in_tmpdir;

  my $ok = eval {
    ## no critic Punctuation
    my $wd = File::pushd::pushd($target);
    my @cmd = $arg->{install_command}
            ? @{ $arg->{install_command} }
            : (cpanm => ".");

    $self->log_debug([ 'installing via %s', \@cmd ]);
    system(@cmd) && $self->log_fatal([ "error running %s", \@cmd ]);
    1;
  };

  unless ($ok) {
    my $error = $@ || '(exception clobered)';
    $self->log("install failed, left failed dist in place at $target");
    die $error;
  }

  if ($arg->{keep_build_dir}) {
    $self->log("all's well; left dist in place at $target");
  } else {
    $self->log("all's well; removing $target");
    $target->rmtree;
    $latest->remove if $latest;
  }

  return;
}

=method test

  $zilla->test(\%arg);

This method builds a new copy of the distribution and tests it using
C<L</run_tests_in>>.

C<\%arg> may be omitted.  Otherwise, valid arguments are:

  keep_build_dir  - if true, don't rmtree the build dir, even if everything
                    seemed to work

=cut

sub test {
  my ($self, $arg) = @_;

  $self->log_fatal("you can't test without any TestRunner plugins")
    unless my @testers = @{ $self->plugins_with(-TestRunner) };

  my ($target, $latest) = $self->ensure_built_in_tmpdir;
  my $error  = $self->run_tests_in($target, $arg);

  if ($arg and $arg->{keep_build_dir}) {
    $self->log("all's well; left dist in place at $target");
    return;
  }

  $self->log("all's well; removing $target");
  $target->rmtree;
  $latest->remove if $latest;
}

=method run_tests_in

  my $error = $zilla->run_tests_in($directory, $arg);

This method runs the tests in $directory (a Path::Class::Dir), which
must contain an already-built copy of the distribution.  It will throw an
exception if there are test failures.

It does I<not> set any of the C<*_TESTING> environment variables, nor
does it clean up C<$directory> afterwards.

=cut

sub run_tests_in {
  my ($self, $target, $arg) = @_;

  $self->phase('TestRunner', 'test_in', $target, $arg )
    or $self->log_fatal("you can't test without any TestRunner plugins");
}

=method run_in_build

  $zilla->run_in_build( \@cmd );

This method makes a temporary directory, builds the distribution there,
executes all the dist's L<BuildRunner|Dist::Zilla::Role::BuildRunner>s
(unless directed not to, via C<< $arg->{build} = 0 >>), and
then runs the given command in the build directory.  If the command exits
non-zero, the directory will be left in place.

=cut

sub run_in_build {
  my ($self, $cmd, $arg) = @_;

  $self->log_fatal("you can't build without any BuildRunner plugins")
    unless ($arg and exists $arg->{build} and ! $arg->{build})
        or @{ $self->plugins_with(-BuildRunner) };

  require "Config.pm"; # skip autoprereq

  my ($target, $latest) = $self->ensure_built_in_tmpdir;
  my $abstarget = $target->absolute;

  # building the dist for real
  my $ok = eval {
    my $wd = File::pushd::pushd($target);

    if ($arg and exists $arg->{build} and ! $arg->{build}) {
      system(@$cmd) and die "error while running: @$cmd";
      return 1;
    }

    $self->_ensure_blib;

    local $ENV{PERL5LIB} = join $Config::Config{path_sep},
      (map { $abstarget->subdir('blib', $_) } qw(arch lib)),
      (defined $ENV{PERL5LIB} ? $ENV{PERL5LIB} : ());

    local $ENV{PATH} = join $Config::Config{path_sep},
      (map { $abstarget->subdir('blib', $_) } qw(bin script)),
      (defined $ENV{PATH} ? $ENV{PATH} : ());

    system(@$cmd) and die "error while running: @$cmd";
    1;
  };

  if ($ok) {
    $self->log("all's well; removing $target");
    $target->rmtree;
    $latest->remove if $latest;
  } else {
    my $error = $@ || '(unknown error)';
    $self->log($error);
    $self->log_fatal("left failed dist in place at $target");
  }
}

# Ensures that a F<blib> directory exists in the build, by invoking all
# C<-BuildRunner> plugins to generate it.  Useful for commands that operate on
# F<blib>, such as C<test> or C<run>.

sub _ensure_blib {
  my ($self) = @_;

  unless ( -d 'blib' ) {
    $self->phase('BuildRunner', 'build')
      or $self->log_fatal("no BuildRunner plugins specified");
    $self->log_fatal("no blib; failed to build properly?") unless -d 'blib';
  }
}

__PACKAGE__->meta->make_immutable;
1;
