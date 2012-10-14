package Dist::Zilla::PluginBundle::FilterVersionTest;

our $VERSION = '0.01';

use Moose;

with 'Dist::Zilla::Role::PluginBundle::Easy';

sub configure {
    my ( $self ) = @_;

    $self->add_plugins(['FakeRelease']);
}

__PACKAGE__->meta->make_immutable;

1;
