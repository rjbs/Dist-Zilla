package Dist::Zilla::Plugin::UploadToCPAN;
# ABSTRACT: upload the dist to CPAN
use Moose;
with 'Dist::Zilla::Role::Releaser';

use CPAN::Uploader 0.101550; # ua string
use File::HomeDir;
use File::Spec;
use Moose::Util::TypeConstraints;
use Scalar::Util qw(weaken);

use namespace::autoclean;

=head1 SYNOPSIS

If loaded, this plugin will allow the F<release> command to upload to the CPAN.

=head1 DESCRIPTION

This plugin looks for configuration in your C<dist.ini> or (more
likely) C<~/.dzil/config.ini>:

  [%PAUSE]
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
  sub _ua_string { CPAN::Uploader->_ua_string }

  sub log {
    my $self = shift;
    $self->{'Dist::Zilla'}{plugin}->log(@_);
  }
}

has credentials_stash => (
  is  => 'ro',
  isa => 'Str',
  default => 'PAUSE'
);

has _credentials_stash_obj => (
  is   => 'ro',
  isa  => maybe_type( role_type('Dist::Zilla::Stash::PAUSE') ),
  lazy => 1,
  init_arg => undef,
  default  => sub { $_[0]->zilla->stash_named( $_[0]->credentials_stash ) },
);

sub _credential {
  my ($self, $name) = @_;

  return unless my $stash = $self->_credentials_stash_obj;
  return $stash->$name;
}

has user => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  required => 1,
  default  => sub {
    my ($self) = @_;
    return $self->_credential('user') || $self->pause_cfg->{user};
  },
);

has password => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  required => 1,
  default  => sub {
    my ($self) = @_;
    return $self->_credential('password') || $self->pause_cfg->{password};
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
