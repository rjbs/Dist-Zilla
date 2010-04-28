use 5.008;
use strict;
use warnings;

package Dist::Zilla::App::Command::listdeps;

# ABSTRACT: print your distribution's prerequisites
use Dist::Zilla::App -command;
use Moose::Autobox;
use Capture::Tiny 'capture';

sub abstract { "print your distribution's prerequisites" }

sub execute {
    my ($self, $opt, $arg) = @_;
    capture {
        $_->before_build for $self->zilla->plugins_with(-BeforeBuild)->flatten;
        $_->gather_files for $self->zilla->plugins_with(-FileGatherer)->flatten;
        $_->prune_files  for $self->zilla->plugins_with(-FilePruner)->flatten;
        $_->munge_files  for $self->zilla->plugins_with(-FileMunger)->flatten;
        $_->register_prereqs for $self->zilla->plugins_with(-PrereqSource)->flatten;
    };
    my $prereq = $self->zilla->prereq->as_distmeta;
    my %req;
    for (qw(requires build_requires configure_requires)) {
        $req{$_}++ for keys %{ $prereq->{$_} || {} };
    }
    delete $req{perl};
    print map { "$_\n" } sort keys %req;
}
1;


=encoding utf8
=head1 SYNOPSIS

    # dzil listdeps | xargs cpan

=head1 DESCRIPTION

This is a command plugin for L<Dist::Zilla>. It provides the C<listdeps>
command, which prints your distribution's prerequisites. You could pipe that
list to a CPAN client like L<cpan> to install all of the dependecies in one
quick go.

=head1 ACKNOWLEDGEMENTS

This code is more or less a direct copy of Marcel Grünauer (hanekomu)
Dist::Zilla::App::Command::prereqs, updated to work with the Dist::Zilla v2
API.

=cut

