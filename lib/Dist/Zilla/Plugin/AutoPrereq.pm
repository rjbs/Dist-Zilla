use 5.010;
use strict;
use warnings;

package Dist::Zilla::Plugin::AutoPrereq;
# ABSTRACT: automatically extract prereqs from your modules

use Dist::Zilla::Util;
use Moose;
use MooseX::Has::Sugar;
use PPI;
use version;

with 'Dist::Zilla::Role::FixedPrereqs';

# -- attributes

# skiplist - a regex
has skip => ( ro, predicate=>'has_skip' );


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
    my $content = $p->_nonpod;
    my $doc = PPI::Document->new( \$content );

    # regular use and require
    my $includes = $doc->find('Statement::Include') || [];
    foreach my $node ( @$includes ) {
        # minimum perl version
        if ( $node->version ) {
            $prereqs{perl} = $node->version;
            next;
        }

        # skipping pragamata
        next if $node->module ~~ [ qw{ strict warnings lib } ];

        if ( $node->module ~~ [ qw{ base parent } ] ) {
            # the content is in the 5th token
            my $meat = $node->child(4);
            my @parents = $meat->isa('PPI::Token::QuoteLike::Words')
                ? ( $meat->literal )
                : ( $meat->string  );
            @prereqs{ @parents } = (0) x @parents;

            # base is in perl core, parent isn't
            next if $node->module eq 'base';
        }

        # regular modules
        my $version = $node->module_version
            ? $node->module_version->content
            : 0;
        $prereqs{ $node->module } = $version;
    }

    # for moose specifics, let's fetch top-level statements
    my @statements =
        grep { $_->child(0)->isa('PPI::Token::Word') }
        grep { ref($_) eq 'PPI::Statement' } # no ->isa()
        $doc->children;

    # roles: with ...
    my @roles =
        map  { $_->child(2)->string }
        grep { $_->child(0)->literal eq 'with' }
        @statements;
    @prereqs{ @roles } = (0) x @roles;

    # inheritance: extends ...
    my @bases =
        map  { $_->string }
        grep { $_->isa('PPI::Token::Quote') }
        map  { $_->children }
        grep { $_->child(0)->literal eq 'extends' }
        @statements;
    @prereqs{ @bases } = (0) x @bases;

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

The extraction may not be perfect but tries to do its best. It will
currently find the following prereqs:

=over 4

=item * plain lines beginning with C<use> or C<require> in your perl
modules and scripts. This includes minimum perl version.

=item * regular inheritance declated with the C<base> and C<parent>
pragamata.

=item * L<Moose> inheritance declared with the C<extends> keyword.

=item * L<Moose> roles included with the C<with> keyword.

=back

If some prereqs are not found, you can still add them manually with the
L<Dist::Zilla::Plugin::Prereq> plugin.

It will trim the following pragamata: C<strict>, C<warnings>, C<base>
and C<lib>. However, C<parent> is kept, since it's not in a core module.

It will also trim the modules shipped within your dist.

The module accept the following options:

=over 4

=item * skip: a regex that will remove any matching modules found
from prereqs.

=back



=head1 SEE ALSO

You can look for information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-AutoPrereq>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-AutoPrereq>

=item * Mailing-list (same as L<Dist::Zilla>)

L<http://www.listbox.com/subscribe/?list_id=139292>

=item * Git repository

L<http://github.com/jquelin/dist-zilla-plugin-autoprereq>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-Plugin-AutoPrereq>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-AutoPrereq>

=back

