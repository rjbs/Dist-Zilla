package Dist::Zilla::Role::ShareDir;
# ABSTRACT: something that picks a directory to install as shared files

use Moose::Role;
with 'Dist::Zilla::Role::FileFinder';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

# Must return a hashref with any of the keys 'dist' and 'module'.  The 'dist'
# must be a scalar with a directory to include and 'module' must be a hashref
# mapping module names to directories to include.  If there are no directories
# to include, it must return undef.
requires 'share_dir_map';

1;
