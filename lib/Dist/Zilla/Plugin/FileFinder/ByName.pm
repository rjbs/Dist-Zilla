package Dist::Zilla::Plugin::FileFinder::ByName;
# ABSTRACT: FileFinder matching on pathnames

use Moose;
with 'Dist::Zilla::Role::FileFinder';

use Dist::Zilla::Dialect;

use namespace::autoclean;

=head1 SYNOPSIS

In your F<dist.ini>:

  [FileFinder::ByName / MyFiles]
  dir   = bin     ; look in the bin/ directory
  dir   = lib     ; and the lib/ directory
  file  = *.pl    ; for .pl files
  match = \.pm$   ; and for .pm files
  skip  = ignore  ; that don't have "ignore" in the path

=head1 CREDITS

This plugin was originally contributed by Christopher J. Madsen.

=cut

use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw(ArrayRef RegexpRef Str);

use Text::Glob 0.08 qw(glob_to_regex_string);

=attr dir

The file must be located in one of the specified directories (relative
to the root directory of the dist).

=attr file

The filename must match one of the specified patterns (which are
converted to regexs using L<Text::Glob> and combined with any C<match>
rules).

=cut

has dirs => (
  is       => 'ro',
  isa      => ArrayRef[Str],
  default  => sub { [] },
);

has files => (
  is      => 'ro',
  isa      => ArrayRef[Str],
  default => sub { [] },
);

{
  my $type = subtype as ArrayRef[RegexpRef];
  coerce $type, from ArrayRef[Str], via { [map { qr/$_/ } @$_] };

=attr match

The pathname must match one of these regular expressions.

=attr skip

The pathname must I<not> match any of these regular expressions.

=cut

  has matches => (
    is      => 'ro',
    isa     => $type,
    coerce  => 1,
    default => sub { [] },
  );

  has skips => (
    is      => 'ro',
    isa     => $type,
    coerce  => 1,
    default => sub { [] },
  );
}

sub mvp_aliases { +{ qw(
  dir      dirs
  file     files
  match    matches
  matching matches
  skip     skips
  except   skips
) } }

sub mvp_multivalue_args { qw(dirs files matches skips) }

sub _join_re {
  my $list = shift;
  return undef unless @$list;
  # Special case to avoid stringify+compile
  return $list->[0] if @$list == 1;
  # Wrap each element to ensure that alternations are isolated
  my $re = join('|', map { "(?:$_)" } @$list);
  qr/$re/
}

sub find_files {
  my $self = shift;

  my $skip  = _join_re($self->skips);
  my $dir   = _join_re([ map { qr!^\Q$_/! } $self->dirs->@* ]);
  my $match = _join_re([
    (map { my $re = glob_to_regex_string($_); qr!(?:\A|/)$re\z! }
         $self->files->@*),
    @{ $self->matches }
  ]);

  my $files = $self->zilla->files;

  $files = [ grep {
    my $name = $_->name;
    (not defined $dir   or $name =~ $dir)   and
    (not defined $match or $name =~ $match) and
    (not defined $skip  or $name !~ $skip)
  } @$files ];

  $self->log_debug("No files found") unless @$files;
  $self->log_debug("Found " . $_->name) for @$files;

  $files;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 DESCRIPTION

FileFinder::ByName is a L<FileFinder|Dist::Zilla::Role::FileFinder> that
selects files by matching the criteria you specify against the pathname.

There are three types of criteria you can use.  C<dir> limits the
search to a particular directory.  C<match> is a regular expression
that must match the pathname.  C<skip> is a regular expression that
must not match the pathname.

Each key can be specified multiple times.  Multiple occurrences of the
same key are ORed together.  Different keys are ANDed together.  That
means that to be selected, a file must be located in one of the
C<dir>s, must match one of the C<match> regexs, and must not match any
of the C<skip> regexs.

Note that C<file> and C<match> are considered to be the I<same> key.
They're just different ways to write a regex that the pathname must match.

Omitting a particular key means that criterion will not apply to the
search.  Omitting all keys will select every file in your dist.

Note: If you need to OR different types of criteria, then use more
than one instance of FileFinder::ByName.  A
L<FileFinderUser|Dist::Zilla::Role::FileFinderUser> should allow you
to specify more than one FileFinder to use.

=for Pod::Coverage
mvp_aliases
mvp_multivalue_args
find_files
