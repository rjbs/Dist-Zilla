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
  for my $name (keys %{ $self->zilla->_global_stashes }) {
    print "[ $name ]\n";
    print Data::Dumper::Dumper($self->zilla->_global_stashes->{ $name });
  }
}

1;
