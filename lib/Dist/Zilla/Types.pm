package Dist::Zilla::Types;
# ABSTRACT: dzil-specific type library

use namespace::autoclean;

=head1 OVERVIEW

This library provides L<MooseX::Types> types for use by Dist::Zilla.  These
types are not (yet?) for public consumption, and you should not rely on them.

Dist::Zilla uses a number of types found in L<MooseX::Types::Perl>.  Maybe
that's what you want.

=cut

use MooseX::Types -declare => [qw(
  License OneZero YesNoStr ReleaseStatus 
  Path ArrayRefOfPaths
  _Filename
  VersionStr
)];
use MooseX::Types::Moose qw(Str Int Defined ArrayRef);
use Path::Tiny;

subtype License, as class_type('Software::License');

subtype Path, as class_type('Path::Tiny');
coerce Path, from Defined, via {
  require Dist::Zilla::Path;
  Dist::Zilla::Path::path($_);
};

subtype ArrayRefOfPaths, as ArrayRef[Path];
coerce ArrayRefOfPaths, from ArrayRef[Defined], via {
  require Dist::Zilla::Path;
  [ map { Dist::Zilla::Path::path($_) } @$_ ];
};

subtype OneZero, as Str, where { $_ eq '0' or $_ eq '1' };

subtype YesNoStr, as Str, where { /\A(?:y|ye|yes)\Z/i or /\A(?:n|no)\Z/i };

subtype ReleaseStatus, as Str, where { /\A(?:stable|testing|unstable)\z/ };

coerce OneZero, from YesNoStr, via { /\Ay/i ? 1 : 0 };

subtype _Filename, as Str,
  where   { $_ !~ qr/(?:\x{0a}|\x{0b}|\x{0c}|\x{0d}|\x{85}|\x{2028}|\x{2029})/ },
  message { "Filename not a Str, or contains a newline or other vertical whitespace" };

use MooseX::Types::Perl qw(LaxVersionStr);
subtype VersionStr, as LaxVersionStr,
  # non-decimal versions cannot use underscores
  where { /_/ && (/^v/ || (()= /\./g) > 1) ? 0 : 1 },
  message { 'Only decimal versions can contain underscores' };

1;
