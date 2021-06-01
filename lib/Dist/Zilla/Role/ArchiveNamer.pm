package Dist::Zilla::Role::ArchiveNamer;
# ABSTRACT: something that names archives

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

requires 'archive_filename';

no Moose::Role;
1;
