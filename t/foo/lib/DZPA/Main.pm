package DZPA::Main;

# perl minimum version
use 5.008;

# under DZPA::, but not shipped by the dist
use DZPA::NotInDist;

# minimum version + comment after the semicolon.
use DZPA::MinVerComment 0.50; # comment

# Moose features
with 'DZPA::Role';
extends 'DZPA::Base';

# DZPA::Skip should be trimmed
use DZPA::Skip::Blah;

# require in a module
require DZPA::ModRequire;

# indented
{
    use DZPA::IndentedUse 0.13;
    require DZPA::IndentedRequire 3.45;
}
__END__
=head1 FOO

this pod should not be taken in to account, with:
use fake;
require blah;
with 'fubar';
