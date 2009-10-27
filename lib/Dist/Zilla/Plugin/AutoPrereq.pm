use strict;
use warnings;

package Dist::Zilla::Plugin::AutoPrereq;
# ABSTRACT: automatically extract prereqs from your modules

use Dist::Zilla::Util;
use Moose;
use version;

with 'Dist::Zilla::Role::FixedPrereqs';

# -- attributes

# skiplist - a regex
has skip => ( is=>'ro', predicate=>'has_skip' );


# -- public methods

sub prereq {
    my $self = shift;
    my $files = $self->zilla->files;

    my %prereqs;
    my @modules;
    foreach my $file ( @$files ) {
        # parse only perl files
        next unless $file->name    =~ /\.(?:pm|pl|t)$/i
            || $file->content =~ /^#!(?:.*)perl(?:$|\s)/;

        # store module name, to trim it from require list later on
        my $module = $file->name;
        $module =~ s{^lib/}{};
        $module =~ s{\.pm$}{};
        $module =~ s{/}{::}g;
        push @modules, $module;

        # parse a file, and merge with existing prereqs
        my %fprereqs = $self->_prereqs_in_file($file);
        foreach my $module ( keys %fprereqs ) {
            my $version = $fprereqs{$module};

            if ( exists $prereqs{$module} ) {
                # prereq already found, check if versions are specified
                if ( _looks_like_version($version) ) {
                    my $vold = version->new( $prereqs{$module} );
                    my $vnew = version->new( $version );
                    $prereqs{$module} = $version if $vnew > $vold;
                }
                # don't bother adding the new prereq, since no version
                # is provided: therefore, the old module has either a
                # more important version or is already undef, and
                # there's no need to replace it

            } else {
                # new prereq, let's add it
                $prereqs{$module} = $version;
            }
        }
    }

    # remove prereqs shipped with current dist
    delete @prereqs{ @modules };

    # remove prereqs from skiplist
    if ( $self->has_skip && $self->skip ) {
        my $skip = $self->skip;
        my $re   = qr/$skip/;
        my @deletes;
        foreach my $k ( keys %prereqs ) {
            push @deletes, $k if $k =~ $re;
        }
        delete @prereqs{ @deletes };
    }

    # we're done, return what we've found
    return \%prereqs;
}


#-- private methods

#
# my %prereqs = $autoprereq->_prereqs_in_file( $file );
#
# find the prereqs (hash of module / version) in $file (a
# dist::zilla:file::ondisk object) and return them.
#
sub _prereqs_in_file {
    my ($self, $file) = @_;

    my %prereqs;

    my $p = Dist::Zilla::Util::Nonpod->_new;
    $p->read_string( $file->content );
    my @lines = split /\n/, $p->_nonpod;

    # quick analysis: find only plain use and require
    my @use_lines =
        grep { /^(?:use|require)\s+/ }
        @lines;
    foreach my $line ( @use_lines ) {
        $line =~ s/;.*$//; # trim end of statement
        my (undef, $module, $version) = split /\s+/, $line;

        # trim common pragmata
        next if $module =~ /^(lib|strict|warnings)$/;

        if ( _looks_like_version($module) ) {
            # perl minimum version is a bit special
            $prereqs{perl} = $module;
        } else {
            $prereqs{ $module } = _looks_like_version($version) ? $version : 0;
        }
    }

    # add moose specifics
    my @roles =
        map { /^(?:with|extends)\s+['"]([\w:]+)['"]/ ? ($1) : () }
        @lines;
    @prereqs{ @roles } = (0) x @roles;

    return %prereqs;
}



# -- private subs

#
# my $bool = _looks_like_version( $string );
#
# return true if $string somehow looks like a perl version.
#
sub _looks_like_version {
    my $version = shift;
    return defined $version &&
        $version =~ /\Av?\d+(?:\.[\d_]+)?\z/;
}



no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=begin Pod::Coverage

prereq

=end Pod::Coverage

=head1 SYNOPSIS

In your F<dist.ini>:

    [AutoPrereq]
    skip = ^Foo|Bar$


=head1 DESCRIPTION

This plugin will extract loosely your distribution prerequisites from
your files.

The extraction may not be perfect, since it will only find the
following prereqs:

=over 4

=item * plain lines beginning with C<use> or C<require> in your perl
modules and scripts.

=item * L<Moose> inheritance declared with the C<extends> keyword
(warning: only the first one is currently extracted).

=item * L<Moose> roles included with the C<with> keyword.

=back

If some prereqs are not found, you can still add them manually with the
L<Dist::Zilla::Plugin::Prereq> plugin.

It will trim the following pragamata: C<strict>, C<warnings> and C<lib>.
It will also trim the modules under your dist namespace (eg: for
C<Dist-Zilla>, it will trim all C<Dist::Zilla::*> prereqs found.


The module accept the following options:

=over 4

=item * skip: a regex that will remove any matching modules found
from prereqs.

=back


=head1 BUGS

Please report any bugs or feature request to
C<< <bug-dist-zilla-plugin-autoprereq@rt.cpan.org> >>, or through the web interface
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-Plugin-AutoPrereq>.



