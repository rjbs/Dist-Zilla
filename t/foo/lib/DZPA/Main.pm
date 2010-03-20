package DZPA::Main;
# ABSTRACT: dumb module to test DZPA

# perl minimum version
use 5.008;

# under DZPA::, but not shipped by the dist
use DZPA::NotInDist;

# minimum version + comment after the semicolon.
use DZPA::MinVerComment 0.50; # comment

# Moose features
with 'DZPA::Role';
extends 'DZPA::Base::Moose1', 'DZPA::Base::Moose2';

# inheritance
use base "DZPA::Base::base1";
use base qw{ DZPA::Base::base2 DZPA::Base::base3 };
use parent "DZPA::Base::parent1";
use parent qw{ DZPA::Base::parent2 DZPA::Base::parent3 };

# DZPA::Skip should be trimmed
use DZPA::Skip::Blah;

# require in a module
require DZPA::ModRequire;

# indented
{
    use DZPA::IndentedUse 0.13;
    require DZPA::IndentedRequire 3.45;
}

use DZPA::IgnoreAPI
    require => 1; # module pluggable has such an api
print qw{
    use !!
};

__END__
=head1 FOO

this pod should not be taken in to account, with:
use fake;
require blah;
with 'fubar';
