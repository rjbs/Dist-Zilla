package Dist::Zilla::Plugin::FileFinder::Filter;
use Moose;
with(
  'Dist::Zilla::Role::FileFinder',
  'Dist::Zilla::Role::FileFinderUser' => {
    default_finders => [],
  },
);
# ABSTRACT: filter matches from other FileFinders

use namespace::autoclean;

=head1 SYNOPSIS

In your F<dist.ini>:

  [FileFinder::Filter / MyFiles]
  finder = :InstallModules ; find files from :InstallModules
  finder = :ExecFiles      ; or :ExecFiles
  skip  = ignore           ; that don't have "ignore" in the path

=head1 CREDITS

This plugin was originally contributed by Christopher J. Madsen.

=cut

use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw(ArrayRef RegexpRef Str);

{
  my $type = subtype as ArrayRef[RegexpRef];
  coerce $type, from ArrayRef[Str], via { [map { qr/$_/ } @$_] };

=attr finder

A FileFinder to supply the initial list of files.
May occur multiple times.

=attr skip

The pathname must I<not> match any of these regular expressions.
May occur multiple times.

=cut

  has skips => (
    is      => 'ro',
    isa     => $type,
    coerce  => 1,
    default => sub { [] },
  );
}

sub mvp_aliases { +{ qw(
  skip     skips
) } }

sub mvp_multivalue_args { qw(skips) }

sub find_files {
  my $self = shift;

  my $files = $self->found_files;

  foreach my $re (@{ $self->skips }) {
    @$files = grep { $_->name !~ $re } @$files;
  }

  $self->log_debug("No files found") unless @$files;
  $self->log_debug("Found " . $_->name) for @$files;

  $files;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 DESCRIPTION

FileFinder::Filter is a L<FileFinder|Dist::Zilla::Role::FileFinder> that
selects files by filtering the selections of other FileFinders.

You specify one or more FileFinders to generate the initial list of
files.  Any file whose pathname matches any of the C<skip> regexs is
removed from that list.

=for Pod::Coverage
mvp_aliases
mvp_multivalue_args
find_files
