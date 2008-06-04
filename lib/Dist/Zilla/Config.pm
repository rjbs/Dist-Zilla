use strict;
use warnings;
package Dist::Zilla::Config;
# ABSTRACT: read in a dist.ini file
use Config::INI::MVP::Reader;
BEGIN { @ISA = 'Config::INI::MVP::Reader' }

sub multivalue_args { qw(author) }

sub _expand_package {
  my ($self, $package) = @_;

  return $package if $package =~ /^Dist::Zilla::/;

  return $package if $package =~ s/^=//;
  return $package if $package =~ s/^@/Dist::Zilla::PluginBundle::/;
  return $package if $package =~ s/^/Dist::Zilla::Plugin::/; # always succeeds
}

sub finalize {
  my ($self) = @_;
  $self->SUPER::finalize;

  ## no critic
  my $data = $self->{data};

  my $root_config = $data->[0]{'=name'} eq '_' ? shift @$data : {};

  $root_config->{authors} = delete $root_config->{author};

  my @plugins;
  for my $plugin (@$data) {
    my $class = delete $plugin->{'=package'};
    
    if ($class->does('Dist::Zilla::Role::PluginBundle')) {
      push @plugins, $class->bundle_config($plugin);
    } else {
      push @plugins, [ $class => $plugin ];
    }
  }

  $root_config->{plugins} = \@plugins;
  $self->{data} = $root_config;
}

1;
