package Dist::Zilla::Chrome::Test;
# ABSTRACT: the chrome used by Dist::Zilla::Tester

use Moose;

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use MooseX::Types::Moose qw(ArrayRef HashRef Str);
use Dist::Zilla::Types qw(OneZero);
use Log::Dispatchouli 1.102220;

use namespace::autoclean;

has logger => (
  is => 'ro',
  default => sub {
    Log::Dispatchouli->new({
      ident   => 'Dist::Zilla::Tester',
      log_pid => 0,
      to_self => 1,
    });
  }
);

=attr response_for

The response_for attribute (which exists only in the Test chrome) is a
hashref that lets you specify the answer to questions asked by
C<prompt_str> or C<prompt_yn>.  The key is the prompt string.  If the
value is a string, it is returned every time that question is asked.
If the value is an arrayref, the first element is shifted off and
returned every time the question is asked.  If the arrayref is empty
(or the prompt is not listed in the hash), the default answer (if any)
is returned.

Since you can't pass arguments to the Chrome constructor, response_for
is initialized to an empty hash, and you can add entries after
construction with the C<set_response_for> method:

  $chrome->set_response_for($prompt => $response);

=cut

has response_for => (
  isa     => HashRef[ ArrayRef | Str ],
  traits  => [ 'Hash' ],
  default => sub { {} },
  handles => {
    response_for     => 'get',
    set_response_for => 'set',
  },
);

sub prompt_str {
  my ($self, $prompt, $arg) = @_;
  $arg ||= {};

  my $response = $self->response_for($prompt);

  $response = shift @$response if ref $response;

  $response = $arg->{default} unless defined $response;

  $self->logger->log_fatal("no response for test prompt '$prompt'")
    unless defined $response;

  return $response;
}

sub prompt_yn {
  my $self = shift;

  return OneZero->coerce( $self->prompt_str(@_) );
}

sub prompt_any_key { return }

with 'Dist::Zilla::Role::Chrome';
__PACKAGE__->meta->make_immutable;
1;
