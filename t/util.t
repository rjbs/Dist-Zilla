use strict;
use warnings;
use Test::More;

use Dist::Zilla::Util;

sub abstract_from_string {
    my ($str) = @_;
    my $e = Dist::Zilla::Util::PEA->_new;
    $e->read_string($str);
    return $e->{abstract};
}

{
    my $pod = <<'EOP';
=head1 NAME

Term::ReadLine - Perl interface to various C<readline> packages.
If no real package is found, substitutes stubs instead of basic functions.


=head1 SYNOPSIS
EOP

    is abstract_from_string($pod), 'Perl interface to various C<readline> packages.
If no real package is found, substitutes stubs instead of basic functions.';
}

{
    my $pod = <<'EOP';
=head1 NAME

Search::Dict, look - search for key in dictionary file

=head1 SYNOPSIS
EOP

    is abstract_from_string($pod), 'search for key in dictionary file';
}

done_testing;
