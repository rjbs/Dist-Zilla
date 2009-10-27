package Foo;

# perl minimum version
use 5.008;

# under Foo::, but not shipped by the dist
use Foo::Bar;

# minimum version + comment after the semicolon.
use DZPA::Foo 0.50; # comment

# Moose features
with 'DZPA::Role';
extends 'DZPA::Base';

# DZPA::Skip should be trimmed
use DZPA::Skip::Blah;

# require in a module
require DZPA::Bar;

__END__
=head1 FOO

this pod should not be taken in to account, with:
use fake;
require blah;
with 'fubar';
