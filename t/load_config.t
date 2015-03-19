use strict;
use warnings;

use Test::More;
use Test::DZil;
use Test::Fatal;

{
    package Dist::Zilla::PluginBundle::Bunk;
    use Moose;
    with 'Dist::Zilla::Role::PluginBundle::Easy';
    sub configure {
        my $self = shift;
        $self->add_plugins('DoesNotExist');
    }
}

like(
    exception {
        Builder->from_config(
            { dist_root => 't/does-not-exist' },
            {
                add_files => {
                    'source/dist.ini' => simple_ini(
                        'DoesNotExist',
                    ),
                },
            },
        );
    },
    qr/Required plugin Dist::Zilla::Plugin::DoesNotExist isn't installed\.\n\n/,
    'missing plugin is detected properly',
);

like(
    exception {
        Builder->from_config(
            { dist_root => 't/does-not-exist' },
            {
                add_files => {
                    'source/dist.ini' => simple_ini(
                        '@DoesNotExist',
                    ),
                },
            },
        );
    },
    qr/Required plugin bundle Dist::Zilla::PluginBundle::DoesNotExist isn't installed\.\n\n/,
    'missing plugin bundle is detected properly',
);

like(
    exception {
        Builder->from_config(
            { dist_root => 't/does-not-exist' },
            {
                add_files => {
                    'source/dist.ini' => simple_ini(
                        '@Bunk',
                    ),
                },
            },
        );
    },
    # with Config::MVP 2.200009, we get:
    # 'Can't locate object method "section_name" via package "Moose::Meta::Class::__ANON__::SERIAL::17" at lib/Dist/Zilla/Dist/Builder.pm line 269.
    qr/Required plugin Dist::Zilla::Plugin::DoesNotExist isn't installed\.\n\n/,
    'missing plugin within a bundle is detected properly',
);

done_testing;
