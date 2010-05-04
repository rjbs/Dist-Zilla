use strict;
use warnings;
package Dist::Zilla::App;
# ABSTRACT: Dist::Zilla's App::Cmd
use App::Cmd::Setup 0.307 -app; # need ->app in Result of Tester, GLD vers

use Carp ();
use Dist::Zilla::Config::Finder;
use File::HomeDir ();
use Moose::Autobox;
use Path::Class;

sub global_opt_spec {
  return (
    [ "verbose|v:s@", "log additional output" ],
    [ "inc|I=s@",     "additional \@INC dirs", {
        callbacks => { 'always fine' => sub { unshift @INC, @{$_[0]}; } }
    } ]
  );
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

  return $self->{__PACKAGE__}{zilla} ||= do {
    my @v_plugins = $self->global_options->verbose
                  ? grep { length } @{ $self->global_options->verbose }
                  : ();

    my $verbose = $self->global_options->verbose && ! @v_plugins;

    $self->chrome->logger->set_debug($verbose ? 1 : 0);

    my $core_debug = grep { m/\A[-_]\z/ } @v_plugins;

    my $zilla = Dist::Zilla->from_config({
      chrome => $self->chrome,
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
