package Dist::Zilla::Chrome::Term;
# ABSTRACT: chrome used for terminal-based interaction

use Moose;

use Dist::Zilla::Pragmas;

use Digest::MD5 qw(md5);
use Dist::Zilla::Types qw(OneZero);
use Encode ();
use Log::Dispatchouli 1.102220;

use namespace::autoclean;

=head1 OVERVIEW

This class provides a L<Dist::Zilla::Chrome> implementation for use in a
terminal environment.  It's the default chrome used by L<Dist::Zilla::App>.

=cut

sub _str_color {
  my ($str) = @_;

  state %color_for;

  # I know, I know, this is ludicrous, but guess what?  It's my Sunday and I
  # can spend it how I want.
  state $max = ($ENV{COLORTERM}//'') eq 'truecolor' ? 255 : 5;
  state $min = $max == 255 ? 384 : 5;
  state $inc = $max == 255 ?  16 : 1;
  state $fmt = $max == 255 ? 'r%ug%ub%u' : 'rgb%u%u%u';

  return $color_for{$str} //= do {
    my @rgb = map { $_ % $max } unpack 'CCC', md5($str);

    my $i = ($rgb[0] + $rgb[1] + $rgb[2]) % 3;
    while (1) {
      last if $rgb[0] + $rgb[1] + $rgb[2] >= $min;

      my $next = $i++ % 3;

      $rgb[$next] = abs($max - $rgb[$next]);
    }

    sprintf $fmt, @rgb;
  }
}

has logger => (
  is  => 'ro',
  isa => 'Log::Dispatchouli',
  init_arg => undef,
  writer   => '_set_logger',
  lazy => 1,
  builder => '_build_logger',
);

sub _build_logger {
  my $self = shift;
  my $enc = $self->term_enc;

  if ($enc && Encode::resolve_alias($enc)) {
    my $layer = sprintf(":encoding(%s)", $enc);
    binmode( STDOUT, $layer );
    binmode( STDERR, $layer );
  }

  my $logger = Log::Dispatchouli->new({
    ident     => 'Dist::Zilla',
    to_stdout => 1,
    log_pid   => 0,
    to_self   => ($ENV{DZIL_TESTING} ? 1 : 0),
    quiet_fatal => 'stdout',
  });

  if (defined $ENV{DZIL_COLOR} ? $ENV{DZIL_COLOR} : -t *STDOUT) {
    my $stdout = $logger->{dispatcher}->output('stdout');

    $stdout->add_callback(sub {
      require Term::ANSIColor;
      my $message = {@_}->{message};
      return $message unless $message =~ s/\A\[([^\]]+)] //;
      my $prefix = $1;
      return sprintf "[%s] %s",
        Term::ANSIColor::colored([ _str_color($prefix) ], $prefix),
        $message;
    });
  }

  return $logger;
}

has term_ui => (
  is   => 'ro',
  isa  => 'Object',
  lazy => 1,
  default => sub {
    require Term::ReadLine;
    require Term::UI;
    Term::ReadLine->new('dzil')
  },
);

has term_enc => (
  is   => 'ro',
  lazy => 1,
  default => sub {
    require Term::Encoding;
    return Term::Encoding::get_encoding();
  },
);

sub prompt_str {
  my ($self, $prompt, $arg) = @_;
  $arg ||= {};
  my $default = $arg->{default};
  my $check   = $arg->{check};

  require Encode;
  my $term_enc = $self->term_enc;

  my $encode = $term_enc
             ? sub { Encode::encode($term_enc, shift, Encode::FB_CROAK())  }
             : sub { shift };
  my $decode = $term_enc
             ? sub { Encode::decode($term_enc, shift, Encode::FB_CROAK())  }
             : sub { shift };

  if ($arg->{noecho}) {
    require Term::ReadKey;
    Term::ReadKey::ReadMode('noecho');
  }
  my $input_bytes = $self->term_ui->get_reply(
    prompt => $encode->($prompt),
    allow  => $check || sub { length $_[0] },
    (defined $default
      ? (default => $encode->($default))
      : ()
    ),
  );
  if ($arg->{noecho}) {
    Term::ReadKey::ReadMode('normal');
    # The \n ending user input disappears under noecho; this ensures
    # the next output ends up on the next line.
    print "\n";
  }

  my $input = $decode->($input_bytes);
  chomp $input;

  return $input;
}

sub prompt_yn {
  my ($self, $prompt, $arg) = @_;
  $arg ||= {};
  my $default = $arg->{default};

  if (! $self->_isa_tty) {
    if (defined $default) {
      return OneZero->coerce($default);
    }

    $self->logger->log_fatal(
      "want interactive input, but terminal doesn't appear interactive"
    );
  }

  my $input = $self->term_ui->ask_yn(
    prompt  => $prompt,
    (defined $default ? (default => OneZero->coerce($default)) : ()),
  );

  return $input;
}

sub _isa_tty {
  my $isa_tty = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT));
  return $isa_tty;
}

sub prompt_any_key {
  my ($self, $prompt) = @_;
  $prompt ||= 'press any key to continue';

  my $isa_tty = $self->_isa_tty;

  if ($isa_tty) {
    local $| = 1;
    print $prompt;

    require Term::ReadKey;
    Term::ReadKey::ReadMode('cbreak');
    Term::ReadKey::ReadKey(0);
    Term::ReadKey::ReadMode('normal');
    print "\n";
  }
}

with 'Dist::Zilla::Role::Chrome';

__PACKAGE__->meta->make_immutable;
1;
