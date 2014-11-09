package Dist::Zilla::Tester;
# ABSTRACT: a testing-enabling stand-in for Dist::Zilla

use Moose;
extends 'Dist::Zilla::Dist::Builder';

# XXX: Adding this autoclean causes problem.  "Builder" and "Minter" do not
# show in tests.  I'm really not sure why. -- rjbs, 2011-08-19
# use namespace::autoclean;

use autodie;
use Dist::Zilla::Chrome::Test;
use File::pushd ();
use File::Spec;
use File::Temp;
use Dist::Zilla::Path;

use Sub::Exporter::Util ();
use Sub::Exporter -setup => {
  exports => [
    Builder => sub { $_[0]->can('builder') },
    Minter  => sub { $_[0]->can('minter')  },
  ],

  groups  => [ default => [ qw(Builder Minter) ] ],
};

sub from_config {
  my ($self, @arg) = @_;

  # The only thing using a local time zone should be NextRelease.  Normally it
  # defaults to "local," but since some users won't have an automatically
  # determinable time zone, we'll switch to not-local times for testing.
  # -- rjbs, 2015-11-26
  local $Dist::Zilla::Plugin::NextRelease::DEFAULT_TIME_ZONE = 'GMT';

  return $self->builder->from_config(@arg);
}

sub builder { 'Dist::Zilla::Tester::_Builder' }

sub minter { 'Dist::Zilla::Tester::_Minter' }

{
  package
    Dist::Zilla::Tester::_Role;

  use Moose::Role;

  has tempdir_root => (
    is => 'rw', isa => 'Str|Undef',
    writer => '_set_tempdir_root',
  );
  has tempdir_obj => (
    is => 'ro', isa => 'File::Temp::Dir',
    clearer => '_clear_tempdir_obj',
    writer => '_set_tempdir_obj',
  );

  sub DEMOLISH {}
  around DEMOLISH => sub {
    my $orig = shift;
    my $self = shift;

    # File::Temp deletes the directory when it goes out of scope
    $self->_clear_tempdir_obj;

    rmdir $self->tempdir_root if $self->tempdir_root;
    return $self->$orig(@_);
  };

  has tempdir => (
    is   => 'ro',
    writer   => '_set_tempdir',
    init_arg => undef,
  );

  sub clear_log_events {
    my ($self) = @_;
    $self->chrome->logger->clear_events;
  }

  sub log_events {
    my ($self) = @_;
    $self->chrome->logger->events;
  }

  sub log_messages {
    my ($self) = @_;
    [ map {; $_->{message} } @{ $self->chrome->logger->events } ];
  }

  sub slurp_file {
    my ($self, $filename) = @_;

    Dist::Zilla::Path::path(
      $self->tempdir->child($filename)
    )->slurp_utf8;
  }

  sub slurp_file_raw {
    my ($self, $filename) = @_;

    Dist::Zilla::Path::path(
      $self->tempdir->child($filename)
    )->slurp_raw;
  }

  sub _metadata_generator_id { 'Dist::Zilla::Tester' }

  no Moose::Role;
}

{
  package Dist::Zilla::Tester::_Builder;

  use Moose;
  extends 'Dist::Zilla::Dist::Builder';
  with 'Dist::Zilla::Tester::_Role';

  use File::Copy::Recursive qw(dircopy);
  use Dist::Zilla::Path;
  use Data::Difference 'data_diff';

  our $Log_Events = [];
  sub most_recent_log_events {
    return @{ $Log_Events }
  }

  around from_config => sub {
    my ($orig, $self, $arg, $tester_arg) = @_;

    confess "dist_root required for from_config" unless $arg->{dist_root};

    my $source = $arg->{dist_root};

    my $tempdir_root = exists $tester_arg->{tempdir_root}
                     ? $tester_arg->{tempdir_root}
                     : 'tmp';

    mkdir $tempdir_root if defined $tempdir_root and not -d $tempdir_root;

    my $tempdir_obj = File::Temp->newdir(
        CLEANUP => 1,
        (defined $tempdir_root ? (DIR => $tempdir_root) : ()),
    );
    my $tempdir = path($tempdir_obj)->absolute;

    my $root = $tempdir->child('source');
    $root->mkpath;

    dircopy($source, $root);

    if ($tester_arg->{also_copy}) {
      while (my ($src, $dest) = each %{ $tester_arg->{also_copy} }) {
        dircopy($src, $tempdir->child($dest));
      }
    }

    if (my $files = $tester_arg->{add_files}) {
      while (my ($name, $content) = each %$files) {
        die "Unix path '$name' does not seem to be portable to the current OS"
          if !unix_path_seems_portable($name);
        my $fn = $tempdir->child($name);
        $fn->parent->mkpath;
        Dist::Zilla::Path::path($fn)->spew_utf8($content);
      }
    }

    local $arg->{dist_root} = "$root";
    local $arg->{chrome} = Dist::Zilla::Chrome::Test->new;

    $Log_Events = $arg->{chrome}->logger->events;

    local @INC = map {; ref($_) ? $_ : File::Spec->rel2abs($_) } @INC;

    local $ENV{DZIL_GLOBAL_CONFIG_ROOT};
    $ENV{DZIL_GLOBAL_CONFIG_ROOT} = $tester_arg->{global_config_root}
      if defined $tester_arg->{global_config_root};

    my $zilla = $self->$orig($arg);

    $zilla->_set_tempdir_root($tempdir_root);
    $zilla->_set_tempdir_obj($tempdir_obj);
    $zilla->_set_tempdir($tempdir);

    return $zilla;
  };

  around build_in => sub {
    my ($orig, $self, $target) = @_;

    # XXX: We *must eliminate* the need for this!  It's only here because right
    # now building a dist with (root <> cwd) doesn't work. -- rjbs, 2010-03-08
    my $wd = File::pushd::pushd($self->root);

    $target ||= do {
      my $target = path($self->tempdir)->child('build');
      $target->mkpath;
      $target;
    };

    return $self->$orig($target);
  };

  around ['test', 'release'] => sub {
    my ($orig, $self) = @_;

    # XXX: We *must eliminate* the need for this!  It's only here because right
    # now building a dist with (root <> cwd) doesn't work. -- rjbs, 2010-03-08
    my $wd = File::pushd::pushd($self->root);

    return $self->$orig;
  };

  no Moose;

  sub unix_path_seems_portable {
    return 1 if $^O eq "linux"; # this check only makes sense on non-unixes

    my ($unix_path) = @_;

    # split the  $unix_path into 3 strings: $volume, $directories, $file; with:
    my @native_parts = File::Spec->splitpath($unix_path); # current OS rules
    my @unix_parts = File::Spec::Unix->splitpath($unix_path); # unix rules
    return if data_diff( \@native_parts, \@unix_parts );

    # split the $directories string into a list of the sub-directories; with:
    my @native_dirs = File::Spec->splitdir($native_parts[1]); # current OS rules
    my @unix_dirs = File::Spec::Unix->splitdir($unix_parts[1]); # unix rules
    return if data_diff( \@native_dirs, \@unix_dirs );

    return 1;
  }
}

{
  package Dist::Zilla::Tester::_Minter;

  use Moose;
  extends 'Dist::Zilla::Dist::Minter';
  with 'Dist::Zilla::Tester::_Role';

  use File::Copy::Recursive qw(dircopy);
  use Dist::Zilla::Path;

  our $Log_Events = [];
  sub most_recent_log_events {
    return @{ $Log_Events }
  }

  sub _mint_target_dir {
    my ($self) = @_;

    my $name = $self->name;
    my $dir  = $self->tempdir->child('mint')->absolute;

    $self->log_fatal("$dir already exists") if -e $dir;

    return $dir;
  }

  sub _setup_global_config {
    my ($self, $dir, $arg) = @_;

    my $config_base = path($dir)->child('config');

    my $stash_registry = {};

    require Dist::Zilla::MVP::Assembler::GlobalConfig;
    require Dist::Zilla::MVP::Section;
    my $assembler = Dist::Zilla::MVP::Assembler::GlobalConfig->new({
      chrome => $arg->{chrome},
      stash_registry => $stash_registry,
      section_class  => 'Dist::Zilla::MVP::Section', # make this DZMA default
    });

    require Dist::Zilla::MVP::Reader::Finder;
    my $reader = Dist::Zilla::MVP::Reader::Finder->new;

    my $seq = $reader->read_config($config_base, { assembler => $assembler });

    return $stash_registry;
  }

  around _new_from_profile => sub {
    my ($orig, $self, $profile_data, $arg, $tester_arg) = @_;

    my $tempdir_root = exists $tester_arg->{tempdir_root}
                     ? $tester_arg->{tempdir_root}
                     : 'tmp';

    mkdir $tempdir_root if defined $tempdir_root and not -d $tempdir_root;

    my $tempdir_obj = File::Temp->newdir(
        CLEANUP => 1,
        (defined $tempdir_root ? (DIR => $tempdir_root) : ()),
    );
    my $tempdir = path($tempdir_obj)->absolute;

    local $arg->{chrome} = Dist::Zilla::Chrome::Test->new;
    $Log_Events = $arg->{chrome}->logger->events;

    local @INC = map {; ref($_) ? $_ : File::Spec->rel2abs($_) } @INC;

    my $global_config_root = path($tester_arg->{global_config_root})->absolute;

    local $ENV{DZIL_GLOBAL_CONFIG_ROOT} = $global_config_root;

    my $global_stashes = $self->_setup_global_config(
      $global_config_root,
      { chrome => $arg->{chrome} },
    );

    local $arg->{_global_stashes} = $global_stashes;

    my $zilla = $self->$orig($profile_data, $arg);

    $zilla->_set_tempdir_root($tempdir_root);
    $zilla->_set_tempdir_obj($tempdir_obj);
    $zilla->_set_tempdir($tempdir);

    return $zilla;
  };
}

no Moose; # XXX: namespace::autoclean caused problems -- rjbs, 2011-08-19
__PACKAGE__->meta->make_immutable;
1;
