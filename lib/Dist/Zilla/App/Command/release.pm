use strict;
use warnings;
package Dist::Zilla::App::Command::release;
# ABSTRACT: release your dist to the CPAN
use Dist::Zilla::App -command;

sub abstract { 'test your dist' }

sub run {
  my ($self, $opt, $arg) = @_;
  
  require CPAN::Uploader;
  my $user = $self->config->{pauseid};
  my $pass = $self->config->{password};

  my $tgz = $self->zilla->build_archive;

  CPAN::Uploader->upload_file($tgz, { user => $user, password => $pass }); 
}

1;
