use strict;
use warnings;
package Dist::Zilla::Config;
use base 'Config::INI::MVP::Reader';

sub multivalue_args { qw(author) }

sub finalize {
  my ($self) = @_;
  $self->SUPER::finalize;

  my $data = $self->{data};

  my $root_config = $data->[0]{'=name'} eq '_' ? shift @$data : {};

  $root_config->{authors} = delete $root_config->{author};

  my @plugins;
  for my $plugin (@$data) {
    my $class = delete $plugin->{'=package'};
    
    Carp::croak "'name' is never a valid plugin configuration option"
      if exists $plugin->{plugin_name};

    $plugin->{plugin_name} = delete $plugin->{'=name'};

    push @plugins, [ $class => $plugin ];
  }

  $root_config->{plugins} = \@plugins;
  $self->{data} = $root_config;
}

1;
