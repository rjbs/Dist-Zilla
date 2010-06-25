use strict;
use warnings;
package Dist::Zilla::App;
# ABSTRACT: Dist::Zilla's App::Cmd
use App::Cmd::Setup 0.307 -app; # need ->app in Result of Tester, GLD vers

use Carp ();
use Dist::Zilla::MVP::Reader::Finder;
use File::HomeDir ();
use Moose::Autobox;
use Path::Class;
use Try::Tiny;

sub global_opt_spec {
  return (
    [ "verbose|v:s@", "log additional output" ],
    [ "lib-inc|I=s@",     "additional \@INC dirs", {
        callbacks => { 'always fine' => sub { unshift @INC, @{$_[0]}; } }
    } ]
  );
}

sub _config_root {
  return dir($ENV{DZIL_GLOBAL_CONFIG_ROOT}) if $ENV{DZIL_GLOBAL_CONFIG_ROOT};

  my $homedir = File::HomeDir->my_home
    or Carp::croak("couldn't determine home directory");

  return dir($homedir)->subdir('.dzil');
}

sub _build_global_stashes {
  my ($self) = @_;

  return $self->{__global_stashes__} if $self->{__global_stashes__};

  my $stash_registry = $self->{__global_stashes__} = {};

  my $config_dir  = $self->_config_root;

  my $config_base = $config_dir->file('config');

  require Dist::Zilla::MVP::Assembler::GlobalConfig;
  require Dist::Zilla::MVP::Section;
  my $assembler = Dist::Zilla::MVP::Assembler::GlobalConfig->new({
    chrome => $self->chrome,
    stash_registry => $stash_registry,
    section_class  => 'Dist::Zilla::MVP::Section', # make this DZMA default
  });

  try {
    my $reader = Dist::Zilla::MVP::Reader::Finder->new({
      if_none => sub {
        warn <<'END_WARN';
WARNING: No global configuration file was found in ~/.dzil -- this limits the
ability of Dist::Zilla to perform some tasks.  You can run "dzil setup" to
create a simple first-pass configuration file, or you can touch the file
~/.dzil/config.ini to suppress this message in the future.
END_WARN
        return $_[2]->{assembler}->sequence
      },
    });

    my $seq = $reader->read_config($config_base, { assembler => $assembler });
  } catch {
    die <<'END_DIE';

Your global configuration file couldn't be loaded.  It's a file matching
~/.dzil/config.*

You can try deleting the file or you might need to upgrade from pre-version 4
format.  In most cases, this will just mean replacing [!release] with [%PAUSE]
and deleting any [!new] stanza.
END_DIE
  };

  return $stash_registry;
}

=method zilla

This returns the Dist::Zilla object in use by the command.  If none has yet
been constructed, one will be by calling C<< Dist::Zilla->from_config >>.

=cut

sub chrome {
  my ($self) = @_;
  require Dist::Zilla::Chrome::Term;

  return $self->{__chrome__} if $self->{__chrome__};

  $self->{__chrome__} = Dist::Zilla::Chrome::Term->new;

  my @v_plugins = $self->global_options->verbose
                ? grep { length } @{ $self->global_options->verbose }
                : ();

  my $verbose = $self->global_options->verbose && ! @v_plugins;

  $self->{__chrome__}->logger->set_debug($verbose ? 1 : 0);

  return $self->{__chrome__};
}

sub zilla {
  my ($self) = @_;

  require Dist::Zilla;

  return $self->{'' . __PACKAGE__}{zilla} ||= do {
    my @v_plugins = $self->global_options->verbose
                  ? grep { length } @{ $self->global_options->verbose }
                  : ();

    my $verbose = $self->global_options->verbose && ! @v_plugins;

    $self->chrome->logger->set_debug($verbose ? 1 : 0);

    my $core_debug = grep { m/\A[-_]\z/ } @v_plugins;

    my $zilla = Dist::Zilla->from_config({
      chrome => $self->chrome,
      _global_stashes => $self->_build_global_stashes,
    });

    $zilla->logger->set_debug($verbose ? 1 : 0);

    VERBOSE_PLUGIN: for my $plugin_name (grep { ! m{\A[-_]\z} } @v_plugins) {
      my @plugins = grep { $_->plugin_name =~ /\b\Q$plugin_name\E\b/ }
                    $zilla->plugins->flatten;

      $zilla->log_fatal("can't find plugins matching $plugin_name to set debug")
        unless @plugins;

      $_->logger->set_debug(1) for @plugins;
    }

    $zilla;
  }
}

1;
