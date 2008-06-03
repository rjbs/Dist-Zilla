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
    
    if ($class->does('Dist::Zilla::Role::PluginBundle')) {
      push @plugins, $class->bundle_config;
    } else {
      push @plugins, [ $class => $plugin ];
    }
  }

  $root_config->{plugins} = \@plugins;
  $self->{data} = $root_config;
}

1;
