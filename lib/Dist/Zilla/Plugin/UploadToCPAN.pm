package Dist::Zilla::Plugin::UploadToCPAN;
# ABSTRACT: upload the dist to CPAN
use Moose;
with 'Dist::Zilla::Role::Releaser';

use CPAN::Uploader 0.100660; # log method
use File::HomeDir;
use File::Spec;
use Scalar::Util qw(weaken);

use namespace::autoclean;

=head1 SYNOPSIS

If loaded, this plugin will allow the F<release> command to upload to the CPAN.

=head1 DESCRIPTION

This plugin looks for configuration in your C<dist.ini> or
C<~/.dzil/config.ini>:

  [=Dist::Zilla::App::Command::release]
  user     = YOUR-PAUSE-ID
  password = YOUR-PAUSE-PASSWORD

If this configuration does not exist, it can read the configuration from
C<~/.pause>, in the same format that L<cpan-upload> requires:

  user YOUR-PAUSE-ID
  password YOUR-PAUSE-PASSWORD

=cut

{
  package
    Dist::Zilla::Plugin::UploadToCPAN::_Uploader;
  use base 'CPAN::Uploader';
  sub log {
    my $self = shift;
    $self->{'Dist::Zilla'}{plugin}->log(@_);
  }
}

has user => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  required => 1,
  default  => sub {
    my ($self) = @_;
    my $user = $self->_global_config_for('Dist::Zilla::App::Command::release')->{user};
    return $user if defined $user;
    return $self->pause_cfg->{user};
  },
);

has password => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  required => 1,
  default  => sub {
    my ($self) = @_;
    my $pass = $self->_global_config_for('Dist::Zilla::App::Command::release')->{password};
    return $pass if defined $pass;
    return $self->pause_cfg->{password};
  },
);

has pause_cfg_file => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    File::Spec->catfile(File::HomeDir->my_home, '.pause');
  },
);

has pause_cfg => (
  is      => 'ro',
  isa     => 'HashRef[Str]',
  lazy    => 1,
  default => sub {
    my $self = shift;
    open my $fh, '<', $self->pause_cfg_file
      or return {};
    my %ret;
    # basically taken from the parsing code used by cpan-upload
    # (maybe this should be part of the CPAN::Uploader api?)
    while (<$fh>) {
      next if /^\s*(?:#.*)?$/;
      my ($k, $v) = /^\s*(\w+)\s+(.+)$/;
      $ret{$k} = $v;
    }
    return \%ret;
  },
);

has uploader => (
  is   => 'ro',
  isa  => 'CPAN::Uploader',
  lazy => 1,
  default => sub {
    my ($self) = @_;

    my $user     = $self->user;
    my $password = $self->password;

    my $uploader = Dist::Zilla::Plugin::UploadToCPAN::_Uploader->new({
      user     => $user,
      password => $password,
    });

    $uploader->{'Dist::Zilla'}{plugin} = $self;
    weaken $uploader->{'Dist::Zilla'}{plugin};

    return $uploader;
  }
);

sub release {
  my ($self, $archive) = @_;

  $self->uploader->upload_file("$archive");
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
