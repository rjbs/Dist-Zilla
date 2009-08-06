package Foo;
use 5.008;
use DZPA::Foo 0.50; # comment
with 'DZPA::Role';
extends 'DZPA::Base';
use DZPA::Skip::Blah;
require DZPA::Bar;
__END__
=head1 FOO

this pod should not be taken in to account, with:
use fake
require blah
with 'fubar'
