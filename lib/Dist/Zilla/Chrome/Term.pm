package Dist::Zilla::Chrome::Term;
# ABSTRACT: chrome used for terminal-based interaction

use Moose;

=head1 OVERVIEW

This class provides a L<Dist::Zilla::Chrome> implementation for use in a
terminal environment.  It's the default chrome used by L<Dist::Zilla::App>.

=cut

use Dist::Zilla::Types qw(OneZero);
use Encode ();
use Log::Dispatchouli 1.102220;

use namespace::autoclean;

has logger => (
  is  => 'ro',
  isa => 'Log::Dispatchouli',
  init_arg => undef,
  writer   => '_set_logger',
  lazy_build => 1,
);

sub _build_logger {
  my $self = shift;
  my $enc = $self->term_enc;

  if ($enc && Encode::resolve_alias($enc)) {
    my $layer = sprintf(":encoding(%s)", $enc);
    binmode( STDOUT, $layer );
    binmode( STDERR, $layer );
  }

  return Log::Dispatchouli->new({
      ident     => 'Dist::Zilla',
      to_stdout => 1,
      log_pid   => 0,
      to_self   => ($ENV{DZIL_TESTING} ? 1 : 0),
      quiet_fatal => 'stdout',
  });
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
    allow  => $check || sub { defined $_[0] and length $_[0] },
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

  my $input = $self->term_ui->ask_yn(
    prompt  => $prompt,
    (defined $default ? (default => OneZero->coerce($default)) : ()),
  );

  return $input;
}

sub prompt_any_key {
  my ($self, $prompt) = @_;
  $prompt ||= 'press any key to continue';

  my $isa_tty = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT));

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
