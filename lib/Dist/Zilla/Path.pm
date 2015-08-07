use strict;
use warnings;
use utf8;

package Dist::Zilla::Path;

# ABSTRACT: Wrapper for Path::Tiny that provides backcompat and deprecation process for Path::Class

use Path::Tiny 0.052 qw();  # issue 427
use Scalar::Util qw( blessed );
use Sub::Exporter::Progressive -setup => {
    exports => [qw[ path  ]],
    groups  => {
        default => [qw[ path ]],
    }
};

=head1 DESCRIPTION

This module exists to serve as a porting intermediary stage to help transition
between L<< C<Path::Class>|Path::Class >> and L<< C<Path::Tiny>|Path::Tiny >>
by responding to all the methods of both.

Each and every method of C<Path::Tiny> is wrapped, and those that normally
return C<Path::Tiny> objects instead return C<Dist::Zilla::Path> objects.

And each method provided by C<Path::Class::File> and C<Path::Class::Dir> are
similarly proxied, and the return values re-wrapped as C<Dist::Zilla::Path>
objects where ever it makes sense.

However, for C<Path::Class> based methods, warnings are emitted indicating their
short lived future.

This means every place in the C<Dist::Zilla> tree that expects C<Path::Class>
interfaces will still work, albeit with warnings.

And places that expect C<Path::Tiny> interfaces will keep working as they did
before.

And your code is encouraged to switch to C<Path::Tiny> wherever possible.

However, if you encounter non-dzil interfaces that may never switch, now is a
good time to explicitly wrap C<Dist::Zilla::Path> responses before handing
them over.

    my $value = $dzilla->thing_that_returns_dz_path();
    Path::Class::Dir->new( $value );
    $otherapi->method( Path::Class::Dir->new( $value ) );

=cut

use constant { PATH => 0, };

use overload (
    q{""}    => sub    { $_[0]->[PATH] },
    bool     => sub () { 1 },
    fallback => 1,
);

# Why do these filters only rebless
# if by regexing the return value?
#
# path()->stat # is why.

# Filter objects that are Path::Class or Path::Tiny
# coerce them to be Path::Tiny then rebless them as Dist::Zilla::Paths
sub _recast {
    my ($object) = @_;
    return $object unless blessed $object;
    return $object unless ( blessed $object ) =~ /^Path::(Tiny|Class)/;
    return path($object);
}

sub AUTOLOAD_dir {
    my ( $method, $self, @args ) = @_;
    if (wantarray) {
        return map { _recast($_) } Path::Class::Dir->new($self)->$method(@args);
    }
    return _recast( scalar Path::Class::Dir->new($self)->$method(@args) );
}

sub AUTOLOAD_file {
    my ( $method, $self, @args ) = @_;
    if (wantarray) {
        return
          map { _recast($_) } Path::Class::File->new($self)->$method(@args);
    }
    return _recast( scalar Path::Class::File->new($self)->$method(@args) );
}

sub AUTOLOAD_path {
    my ( $method, $self, @args ) = @_;
    if (wantarray) {
        return map { _recast($_) } Path::Tiny::path($self)->$method(@args);
    }
    return _recast( scalar Path::Tiny::path($self)->$method(@args) );
}

our $WARN_LOAD_PATHCLASS_METHODS = 1;
our $WARN_REROUTED_METHODS       = undef;

# This could have been implemented differently without autoload,
# but it would have required `require`ing all PT/PCD/PCF, loading Package::Stash,
# iterating all their symbol tables, dynamically creating subs in ::Path that curried the results
# from the relevant calls, etc, etc.
#
# And that would have also made it impossible to test with
# PERL5OPT="-MDevel::Hide=Path::Class,Path::Class::File,Path::Class::Dir"
#
# So ah, no. Instead, this is a custom dispatch table of some kind.
#
sub AUTOLOAD {
    my $self = shift;
    ( my $meth = our $AUTOLOAD ) =~ s/.+:://;
    return if $meth eq 'DESTROY';

    # If the method is Path::Tiny supported,
    # call it, and wrap the result.
    return AUTOLOAD_path( $meth, $self, @_ ) if Path::Tiny->can($meth);
    if ( $WARN_LOAD_PATHCLASS_METHODS ) {
        require Carp;
        Carp::carp( "$meth called on Dist::Zilla::Path."
          . ' This is deprecated and will go away in a future release' );
    }
    require Module::Runtime;
    for my $module ( qw( Path::Class::Dir Path::Class::File ) ) {
        Module::Runtime::require_module( $module );
    }

    # Otherwise:
    # If the method is provided by /both/ PC:D and PC:F, construct
    # a copy of the most sensible one, call the method,
    # and return the re-wrapped result.

    if ( Path::Class::Dir->can($meth) and Path::Class::File->can($meth) ) {
        if ( -d $self ) {
            return AUTOLOAD_dir( $meth, $self, @_ );
        }
        return AUTOLOAD_file( $meth, $self, @_ );
    }

    # However, if the method is provided by only one of the two,
    # dispatch and wrap to the right one.
    #
    # This is kinda dodgy because essentially, it conflates both
    # method types into the same object so things like $dir->filemethod()
    # and $file->dirmethod() are legal however, thats standard for Path::Tiny
    # anyway.
    return AUTOLOAD_dir( $meth, $self, @_ ) if Path::Class::Dir->can($meth);
    return AUTOLOAD_file( $meth, $self, @_ ) if Path::Class::File->can($meth);
    require Carp;
    Carp::croak( "Can't find resolvant for $meth in any of"
          . ' Path::Tiny, Path::Class::Dir, Path::Class::File' );
}

=head1 FUNCTIONS

=head2 C<path>

    use Dist::Zilla::Path;

    my $path = path('./');

The exact semantics are otherwise detailed in L<< C<Path::Tiny>|Path::Tiny >>.

Function returns a C<Dist::Zilla::Path> object.

=cut

sub path {
    my $pp = Path::Tiny::path(@_);
    return bless $pp, __PACKAGE__;
}


sub file {
    my ( $self, @rest ) = @_;
    if ( $WARN_REROUTED_METHODS ) {
        require Carp;
        Carp::carp( "file called on Dist::Zilla::Path."
          . ' This is deprecated and will go away in a future release' );
    }
    return $self->child( @rest );
}

sub subdir {
    my ( $self, @rest ) = @_;
    if ( $WARN_REROUTED_METHODS ) {
        require Carp;
        Carp::carp( "subdir called on Dist::Zilla::Path."
          . ' This is deprecated and will go away in a future release' );
    }
    return $self->child( @rest );
}

sub dir {
    my ( $self, @rest ) = @_;
    if ( $WARN_REROUTED_METHODS ) {
        require Carp;
        Carp::carp( "dir called on Dist::Zilla::Path."
          . ' This is deprecated and will go away in a future release' );
    }
    return $self->parent( @rest );
}

1;

