package Dist::Zilla::App::Command::setup;
# ABSTRACT: set up a basic global config file

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use Dist::Zilla::App -command;

=head1 SYNOPSIS

  $ dzil setup
  Enter your name> Ricardo Signes
  ...

Dist::Zilla looks for per-user configuration in F<~/.dzil/config.ini>.  This
command prompts the user for some basic information that can be used to produce
the most commonly needed F<config.ini> sections.

B<WARNING>: PAUSE account details are stored within config.ini in plain text.

=cut

use autodie;

sub abstract { 'set up a basic global config file' }

sub description {
  "This command will run through a short interactive process to set up\n" .
  "a basic Dist::Zilla configuration in ~/.dzil/config.ini"
}

sub validate_args {
  my ($self, $opt, $args) = @_;

  $self->usage_error('too many arguments') if @$args != 0;
}

sub execute {
  my ($self, $opt, $arg) = @_;

  my $chrome = $self->app->chrome;

  require Dist::Zilla::Util;
  my $config_root = Dist::Zilla::Util->_global_config_root;

  if (
    -d $config_root
    and
    my @files = grep { -f and $_->basename =~ /\Aconfig\.[^.]+\z/ }
    $config_root->children
  ) {
    $chrome->logger->log_fatal([
      "per-user configuration files already exist in %s: %s",
      "$config_root",
      join(q{, }, @files),
    ]);

    return unless $chrome->prompt_yn("Continue anyway?", { default => 0 });
  }

  my $realname = $chrome->prompt_str(
    "What's your name? ",
    { check => sub { defined $_[0] and $_[0] =~ /\S/ } },
  );

  my $email = $chrome->prompt_str(
    "What's your email address? ",
    { check => sub { defined $_[0] and $_[0] =~ /\A\S+\@\S+\z/ } },
  );

  my $c_holder = $chrome->prompt_str(
    "Who, by default, holds the copyright on your code? ",
    {
      check   => sub { defined $_[0] and $_[0] =~ /\S/ },
      default => $realname,
    },
  );

  my $license = $chrome->prompt_str(
    "What license will you use by default (Perl_5, BSD, etc.)? ",
    {
      default => 'Perl_5',
      check   => sub {
        my $str = String::RewritePrefix->rewrite(
          { '' => 'Software::License::', '=' => '' },
          $_[0],
        );

        return Params::Util::_CLASS($str) && eval "require $str; 1";
      },
    },
  );

  my %pause;

  if (
    $chrome->prompt_yn(
    '
    * WARNING - Your account details will be stored in plain text *
Do you want to enter your PAUSE account details? ',
      { default => 0 },
    )
  ) {
    my $default_pause;
    if ($email =~ /\A(.+?)\@cpan\.org\z/i) {
      $default_pause = uc $1;
    }

    $pause{username} = $chrome->prompt_str(
      "What is your PAUSE id? ",
      {
        check   => sub { defined $_[0] and $_[0] =~ /\A\w+\z/ },
        default => $default_pause,
      },
    );

    $pause{password} = $chrome->prompt_str(
      "What is your PAUSE password? ",
      {
        check   => sub { length $_[0] },
        noecho  => 1,
      },
    );
  }

  $config_root->mkpath unless -d $config_root;
  $config_root->child('profiles')->mkpath
    unless -d $config_root->child('profiles');

  my $umask = umask;
  umask( $umask | 077 ); # this file might contain PAUSE pw; make it go-r
  open my $fh, '>:encoding(UTF-8)', $config_root->child('config.ini');

  $fh->print("[%User]\n");
  $fh->print("name  = $realname\n");
  $fh->print("email = $email\n\n");

  $fh->print("[%Rights]\n");
  $fh->print("license_class    = $license\n");
  $fh->print("copyright_holder = $c_holder\n\n");

  if (keys %pause) {
    $fh->print("[%PAUSE]\n");
    $fh->print("username = $pause{username}\n");
    if (length $pause{password}) {
      $fh->print("password = $pause{password}\n");
    }
    $fh->print("\n");
  }

  close $fh;

  umask $umask;

  $self->log("config.ini file created!");
}

1;
