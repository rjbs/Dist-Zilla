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

# and this comment should not cause a package to be trimmed:
# package foobar DZPA::Role

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

# multiple namespaces; some referencing local packages
package DZPA::Second;

package DZPA::Third;
use parent -norequire => 'DZPA::Second';

use DZPA::Empty;

package # hide from PAUSE
    DZPA::Fourth;


__END__
=head1 FOO

this pod should not be taken in to account, with:
use fake;
require blah;
with 'fubar';

nor should this statement here, but that is still a TODO!
pack age strict;  XXX remove this space
