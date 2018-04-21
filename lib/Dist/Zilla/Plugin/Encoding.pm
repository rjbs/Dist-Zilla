package Dist::Zilla::Plugin::Encoding;
# ABSTRACT: set the encoding of arbitrary files

use Moose;
with 'Dist::Zilla::Role::EncodingProvider';

use Dist::Zilla::Dialect;

use namespace::autoclean;

=head1 SYNOPSIS

This plugin allows you to explicitly set the encoding on some files in your
distribution. You can either specify the exact set of files (with the
"filenames" parameter) or provide the regular expressions to check (using
"match").

In your F<dist.ini>:

  [Encoding]
  encoding = Latin-3

  filename = t/esperanto.t  ; this file is Esperanto
  match     = ^t/urkish/    ; these are all Turkish

=cut

sub mvp_multivalue_args { qw(filenames matches ignore) }
sub mvp_aliases { return { filename => 'filenames', match => 'matches' } }

=attr encoding

This is the encoding to set on the selected files. The special value "bytes"
can be used to indicate raw files that should not be encoded.

=cut

has encoding => (
  is   => 'ro',
  isa  => 'Str',
  required => 1,
);

=attr filenames

This is an arrayref of filenames to have their encoding set.

=cut

has filenames => (
  is   => 'ro',
  isa  => 'ArrayRef',
  default => sub { [] },
);

=attr matches

This is an arrayref of regular expressions.  Any file whose name matches one of
these regex will have its encoding set.

=cut

has matches => (
  is   => 'ro',
  isa  => 'ArrayRef',
  default => sub { [] },
);

=attr ignore

This is an arrayref of regular expressions.  Any file whose name matches one of
these regex will B<not> have its encoding set. Useful to ignore a few files
that would otherwise be selected by C<matches>.

=cut

has ignore => (
  is   => 'ro',
  isa  => 'ArrayRef',
  default => sub { [] },
);

sub set_file_encodings {
  my ($self) = @_;

  # never match (at least the filename characters)
  my $matches_regex = qr/\000/;

  $matches_regex = qr/$matches_regex|$_/ for @{$self->matches};

  # \A\Q$_\E should also handle the `eq` check
  $matches_regex = qr/$matches_regex|\A\Q$_\E/ for @{$self->filenames};

  my( $ignore_regex ) = map { $_ && qr/$_/ } join '|', @{ $self->ignore };

  for my $file (@{$self->zilla->files}) {
    next unless $file->name =~ $matches_regex;

    next if $ignore_regex and $file->name =~ $ignore_regex;

    $self->log_debug([
      'setting encoding of %s to %s',
      $file->name,
      $self->encoding,
    ]);

    $file->encoding($self->encoding);
  }

  return;
}

__PACKAGE__->meta->make_immutable;
1;
