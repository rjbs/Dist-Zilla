package Dist::Zilla::Plugin::AutoPrereq;
# ABSTRACT: automatically extract prereq from your modules

use strict;
use warnings;

use Moose;
with 'Dist::Zilla::Role::FixedPrereqs';


# -- attributes

has _prereqs => (
    is         => 'ro',
    isa        => 'HashRef',
    default    => sub { {} },
);


# -- constructor

sub new {
    my ($class, $arg) = @_;

    my $self = $class->SUPER::new({
        '=name'  => delete $arg->{'=name'},
        zilla    => delete $arg->{zilla},
        _prereqs => $arg,
    });
}



# -- public methods

sub prereq {
    my ($self, $file) = @_;
print "foo\n";
return;
    return $self->_munge_perl($file) if $file->name    =~ /\.(?:pm|pl)$/i;
    return $self->_munge_perl($file) if $file->content =~ /^#!(?:.*)perl(?:$|\s)/;
    return;
}

# -- private methods

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;

__END__

=begin Pod::Coverage

multivalue_args
munge_file

=end Pod::Coverage

=head1 SYNOPSIS

In your F<dist.ini>:

    [Prepender]
    copyright = 1
    line = use strict;
    line = use warnings;

=head1 DESCRIPTION

This plugin will prepend the specified lines in each Perl module or
program within the distribution. For scripts having a shebang line,
lines will be inserted just after it.

This is useful to enforce a set of pragmas to your files (since pragmas
are lexical, they will be active for the whole file), or to add some
copyright comments, as the fsf recommends.

The module accepts the following options in its F<dist.ini> section:

=over 4

=item * copyright - whether to insert a boilerplate copyright comment.
defaults to false.

=item * line - anything you want to add. may be specified multiple
times. no default.

=back

=head1 BUGS

Please report any bugs or feature request to
C<< <bug-dist-zilla-plugin-prepender@rt.cpan.org> >>, or through the web interface
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-Plugin-Prepender>.



