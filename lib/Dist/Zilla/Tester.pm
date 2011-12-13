package Dist::Zilla::Tester;
use Moose;
extends 'Dist::Zilla::Dist::Builder';
# ABSTRACT: a testing-enabling stand-in for Dist::Zilla

# XXX: Adding this autoclean causes problem.  "Builder" and "Minter" do not
# show in in tests.  I'm really not sure why. -- rjbs, 2011-08-19
# use namespace::autoclean;

use autodie;
use Dist::Zilla::Chrome::Test;
use File::pushd ();
use File::Spec;
use File::Temp;

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
  $self->builder->from_config(@arg);
}

sub builder { 'Dist::Zilla::Tester::_Builder' }

sub minter { 'Dist::Zilla::Tester::_Minter' }

{
  package Dist::Zilla::Tester::_Role;
  use Moose::Role;

  has tempdir => (
    is   => 'ro',
    writer   => '_set_tempdir',
    init_arg => undef,
  );

  has _orig_failure_count => (
    is        => 'rw',
    init_arg  => undef,
  );

  sub _current_failure_count {
    scalar grep { !$_ } Test::Builder->new->summary;
  } # end _current_failure_count

  before 'DESTROY' => sub {
    my ($self) = @_;

    my $orig_failures = $self->_orig_failure_count;

    $self->diag_log if defined $orig_failures
        and $self->_current_failure_count > $orig_failures;
  };

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

  sub diag_log {
    my ($self) = @_;

    Test::Builder->new->diag(
      map { "$_->{message}\n" } @{ $self->chrome->logger->events }
    );
  }

  sub slurp_file {
    my ($self, $filename) = @_;

    return scalar do {
      local $/;
      open my $fh, '<', $self->tempdir->file($filename);

      # Win32.
      binmode $fh, ':raw';
      <$fh>;
    };
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
  use Path::Class;

  around from_config => sub {
    my ($orig, $self, $arg, $tester_arg) = @_;

    confess "dist_root required for from_config" unless $arg->{dist_root};

    my $source = $arg->{dist_root};

    my $tempdir_root = exists $tester_arg->{tempdir_root}
                     ? $tester_arg->{tempdir_root}
                     : 'tmp';

    mkdir $tempdir_root if defined $tempdir_root and not -d $tempdir_root;

    my $tempdir = dir( File::Temp::tempdir(
        CLEANUP => 1,
        (defined $tempdir_root ? (DIR => $tempdir_root) : ()),
    ))->absolute;

    my $root = $tempdir->subdir('source');
    $root->mkpath;

    dircopy($source, $root);

    if ($tester_arg->{also_copy}) {
      while (my ($src, $dest) = each %{ $tester_arg->{also_copy} }) {
        dircopy($src, $tempdir->subdir($dest));
      }
    }

    if (my $files = $tester_arg->{add_files}) {
      while (my ($name, $content) = each %$files) {
        my $fn = $tempdir->file($name);
        $fn->dir->mkpath;
        open my $fh, '>', $fn;

        # Win32 fix for crlf translation.
        #   maybe :raw:utf8? -- Kentnl - 2010-06-10
        binmode $fh, ':raw';
        print { $fh } $content;
        close $fh;
      }
    }

    local $arg->{dist_root} = "$root";
    local $arg->{chrome} = Dist::Zilla::Chrome::Test->new;

    local @INC = map {; ref($_) ? $_ : File::Spec->rel2abs($_) } @INC;

    my $zilla = $self->$orig($arg);

    $zilla->_set_tempdir($tempdir);
    $zilla->_orig_failure_count($zilla->_current_failure_count)
        if $tester_arg->{auto_diag};

    return $zilla;
  };

  around build_in => sub {
    my ($orig, $self, $target) = @_;

    # XXX: We *must eliminate* the need for this!  It's only here because right
    # now building a dist with (root <> cwd) doesn't work. -- rjbs, 2010-03-08
    my $wd = File::pushd::pushd($self->root);

    $target ||= do {
      my $target = dir($self->tempdir)->subdir('build');
      $target->mkpath;
      $target;
    };

    return $self->$orig($target);
  };

  around release => sub {
    my ($orig, $self) = @_;

    # XXX: We *must eliminate* the need for this!  It's only here because right
    # now building a dist with (root <> cwd) doesn't work. -- rjbs, 2010-03-08
    my $wd = File::pushd::pushd($self->root);

    return $self->$orig;
  };

  no Moose;
}

{
  package Dist::Zilla::Tester::_Minter;
  use Moose;
  extends 'Dist::Zilla::Dist::Minter';
  with 'Dist::Zilla::Tester::_Role';

  use File::Copy::Recursive qw(dircopy);
  use Path::Class;

  sub _mint_target_dir {
    my ($self) = @_;

    my $name = $self->name;
    my $dir  = $self->tempdir->subdir('mint')->absolute;

    $self->log_fatal("$dir already exists") if -e $dir;

    return $dir;
  }

  sub _setup_global_config {
    my ($self, $dir, $arg) = @_;

    my $config_base = $dir->file('config');

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

    my $tempdir = dir( File::Temp::tempdir(
        CLEANUP => 1,
        (defined $tempdir_root ? (DIR => $tempdir_root) : ()),
    ))->absolute;

    local $arg->{chrome} = Dist::Zilla::Chrome::Test->new;

    local @INC = map {; ref($_) ? $_ : File::Spec->rel2abs($_) } @INC;

    local $ENV{DZIL_GLOBAL_CONFIG_ROOT} = $tester_arg->{global_config_root};

    my $global_stashes = $self->_setup_global_config(
      $tester_arg->{global_config_root},
      { chrome => $arg->{chrome} },
    );

    local $arg->{_global_stashes} = $global_stashes;

    my $zilla = $self->$orig($profile_data, $arg);

    $zilla->_set_tempdir($tempdir);
    $zilla->_orig_failure_count($zilla->_current_failure_count)
        if $tester_arg->{auto_diag};

    return $zilla;
  };
}

no Moose; # XXX: namespace::autoclean caused problems -- rjbs, 2011-08-19
__PACKAGE__->meta->make_immutable;
1;
