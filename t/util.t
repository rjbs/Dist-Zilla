use strict;
use warnings;
use Test::More;

use Dist::Zilla::Util;

sub abstract_from_string {
    my ($str) = @_;
    my $e = Dist::Zilla::Util::PEA->_new;
    $e->parse_string_document($str);
    return $e->{abstract};
}

{
    my $pod = <<'EOP';
=head1 NAME

Term::ReadLine - Perl interface to various C<readline> packages.
If no real package is found, substitutes stubs instead of basic functions.


=head1 SYNOPSIS

=cut

# ABSTRACT: Decoy

EOP

    is abstract_from_string($pod), 'Perl interface to various C<readline> packages. If no real package is found, substitutes stubs instead of basic functions.';
}

{
    my $pod = <<'EOP';
=head1 NAME

Search::Dict, look - search for key in dictionary file

=head1 SYNOPSIS
EOP

    is abstract_from_string($pod), 'search for key in dictionary file';
}

{
    my $pod = <<'EOP';
# ABSTRACT: Do stuff

=head1 NAME

Search::Dict - decoy

=head1 SYNOPSIS
EOP

    is abstract_from_string($pod), 'Do stuff';
}


{
    my $pod = <<'EOP';
=head1 NAME

retropan - Makes a historic minicpan E<9203> E<#9203> E<yuml> E<gt> E<lt> E<verbar> E<sol>

=head1 SYNOPSIS
EOP

    is abstract_from_string($pod), "Makes a historic minicpan \x{23f3} E<#9203> \x{ff} > < | /";
}

{
    my $pod = qq{
=head1 NAME

pound - latin1 \xa3

=head1 SYNOPSIS
};

    is abstract_from_string($pod), "latin1 \xa3";
}

{
    my $pod = qq{
=encoding utf8

=head1 NAME

pound - utf8 \xc2\xa3

=head1 SYNOPSIS
};

    is abstract_from_string($pod), "utf8 \xa3";
}


done_testing;
