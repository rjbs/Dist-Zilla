package Dist::Zilla::Plugin::JustForManifestSkipTests;
use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';

use namespace::autoclean;

__PACKAGE__->meta->make_immutable;
1;

__DATA__
___[ foo.txt ]___
Just for tests...
___[ FOO.SKIP ]___
dist.ini
foo.tx?
bonus/vader.txt
FOO.SKIP
