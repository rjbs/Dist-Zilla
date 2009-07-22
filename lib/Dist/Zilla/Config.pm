package Dist::Zilla::Config;
use Moose::Role;
# ABSTRACT: stored configuration loader role

requires 'read_config';

sub struct_to_config {
  my ($self, $struct) = @_;

  my $i = 0;
  my $root_config = $struct->[0]{'=name'} eq '_'
                  ? $struct->[ $i++ ]
                  : {};

  $root_config->{authors} = delete $root_config->{author};

  my @plugins;
  for my $plugin (map { $struct->[ $_ ] } ($i .. $#$struct)) {
    my $class = delete $plugin->{'=package'};
    
    if (eval { $class->does('Dist::Zilla::Role::PluginBundle') }) {
      push @plugins, $class->bundle_config($plugin);
    } else {
      push @plugins, [ $class => $plugin ];
    }
  }

  return ($root_config, \@plugins);
}

no Moose::Role;
1;
