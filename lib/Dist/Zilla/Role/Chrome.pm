package Dist::Zilla::Role::Chrome;
# ABSTRACT: something that provides a user interface for Dist::Zilla

use Moose::Role;

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

requires 'logger';

requires 'prompt_str';
requires 'prompt_yn';
requires 'prompt_any_key';

1;
