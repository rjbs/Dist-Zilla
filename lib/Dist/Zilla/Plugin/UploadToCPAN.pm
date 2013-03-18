package Dist::Zilla::Plugin::UploadToCPAN;
# ABSTRACT: upload the dist to CPAN
use Moose;
with qw(Dist::Zilla::Role::BeforeRelease Dist::Zilla::Role::Releaser);

use Moose::Util::TypeConstraints;
use Scalar::Util qw(weaken);
use Try::Tiny;

use namespace::autoclean;

=head1 SYNOPSIS

If loaded, this plugin will allow the F<release> command to upload to the CPAN.

=head1 DESCRIPTION

This plugin looks for configuration in your C<dist.ini> or (more
likely) C<~/.dzil/config.ini>:

  [%PAUSE]
  username = YOUR-PAUSE-ID
  password = YOUR-PAUSE-PASSWORD

If this configuration does not exist, it can read the configuration from
C<~/.pause>, in the same format that L<cpan-upload> requires:

  user YOUR-PAUSE-ID
  password YOUR-PAUSE-PASSWORD

If neither configuration exists, it will prompt you to enter your
username and password during the BeforeRelease phase.  Entering a
blank username or password will abort the release.

=cut

has credentials_stash => (
  is  => 'ro',
  isa => 'Str',
  default => '%PAUSE'
);

has _credentials_stash_obj => (
  is   => 'ro',
  isa  => maybe_type( class_type('Dist::Zilla::Stash::PAUSE') ),
  lazy => 1,
  init_arg => undef,
  default  => sub { $_[0]->zilla->stash_named( $_[0]->credentials_stash ) },
);

sub _credential {
  my ($self, $name) = @_;

  return unless my $stash = $self->_credentials_stash_obj;
  return $stash->$name;
}

sub mvp_aliases {
  return { user => 'username' };
}

=attr username

This option supplies the user's PAUSE username.  If not supplied, it will be
looked for in the user's PAUSE configuration.

=cut

has username => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  required => 1,
  default  => sub {
    my ($self) = @_;
    return $self->_credential('username')
        || $self->pause_cfg->{user}
        || $self->zilla->chrome->prompt_str("PAUSE username: ");
  },
);

=attr password

This option supplies the user's PAUSE password.  If not supplied, it will be
looked for in the user's PAUSE configuration.

=cut

has password => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  required => 1,
  default  => sub {
    my ($self) = @_;
    return $self->_credential('password')
        || $self->pause_cfg->{password}
        || $self->zilla->chrome->prompt_str('PAUSE password: ', { noecho => 1 });
  },
);

has pause_cfg_file => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    require File::Spec;
    require File::HomeDir;
    File::Spec->catfile(File::HomeDir->my_home, '.pause');
  },
);

=attr pause_cfg

This is a hashref of defaults loaded from F<~/.pause> -- this attribute is
subject to removal in future versions, as the config-loading behavior in
CPAN::Uploader is improved.

=cut

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

=attr subdir

If given, this specifies a subdirectory under the user's home directory to
which to upload.  Using this option is not recommended.

=cut

has subdir => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_subdir',
);

=attr upload_uri

If given, this specifies an alternate URI for the PAUSE upload form.  By
default, the default supplied by L<CPAN::Uploader> is used.  Using this option
is not recommended in most cases.

=cut

has upload_uri => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_upload_uri',
);

has uploader => (
  is   => 'ro',
  isa  => 'CPAN::Uploader',
  lazy => 1,
  default => sub {
    my ($self) = @_;

    require Dist::Zilla::Plugin::UploadToCPAN::_Uploader;
    my $uploader = Dist::Zilla::Plugin::UploadToCPAN::_Uploader->new({
      user     => $self->username,
      password => $self->password,
      ($self->has_subdir
           ? (subdir => $self->subdir) : ()),
      ($self->has_upload_uri
           ? (upload_uri => $self->upload_uri) : ()),
    });

    $uploader->{'Dist::Zilla'}{plugin} = $self;
    weaken $uploader->{'Dist::Zilla'}{plugin};

    return $uploader;
  }
);

sub before_release {
  my $self = shift;

  my $problem;
  try {
    for my $attr (qw(username password)) {
      $problem = $attr;
      die unless length $self->$attr;
    }
    undef $problem;
  };

  $self->log_fatal(['You need to supply a %s', $problem]) if $problem;
}

sub release {
  my ($self, $archive) = @_;

  $self->uploader->upload_file("$archive");
}

__PACKAGE__->meta->make_immutable;
1;
