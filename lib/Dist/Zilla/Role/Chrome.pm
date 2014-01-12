package Dist::Zilla::Role::Chrome;
# ABSTRACT: something that provides a user interface for Dist::Zilla

use Moose::Role;

use namespace::autoclean;

requires 'logger';

requires 'prompt_str';
requires 'prompt_yn';
requires 'prompt_any_key';

1;
