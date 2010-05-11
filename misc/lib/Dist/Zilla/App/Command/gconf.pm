use strict;
use warnings;
package Dist::Zilla::App::Command::gconf;
# ABSTRACT: dump global config
use Dist::Zilla::App -command;

sub abstract { 'dump global config' }

sub opt_spec {
}

sub execute {
  my ($self, $opt, $arg) = @_;

  require Data::Dumper;
  for my $name ($self->zilla->_global_config->section_names) {
    print "[ $name ]\n";
    print Data::Dumper::Dumper($self->zilla->_global_config_for($name));
  }
}

1;
