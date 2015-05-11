package Dist::Zilla::Plugin::UploadToCPAN;
# ABSTRACT: upload the dist to CPAN

use Moose;
with qw(Dist::Zilla::Role::BeforeRelease Dist::Zilla::Role::Releaser);

use File::Spec;
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

You can't put your password in your F<dist.ini>.  C'mon now!

=cut

{
  package
    Dist::Zilla::Plugin::UploadToCPAN::_Uploader;
  # CPAN::Uploader will be loaded later if used
  our @ISA = 'CPAN::Uploader';
  # Report CPAN::Uploader's version, not ours:
  sub _ua_string { CPAN::Uploader->_ua_string }

  sub log {
    my $self = shift;
    $self->{'Dist::Zilla'}{plugin}->log(@_);
  }
}

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

This option supplies the user's PAUSE username.
It will be looked for in the user's PAUSE configuration; if not
found, the user will be prompted.

=cut

has username => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  default  => sub {
    my ($self) = @_;
    return $self->_credential('username')
        || $self->pause_cfg->{user}
        || $self->zilla->chrome->prompt_str("PAUSE username: ");
  },
);

sub cpanid { shift->username }

=attr password

This option supplies the user's PAUSE password.  It cannot be provided via
F<dist.ini>.  It will be looked for in the user's PAUSE configuration; if not
found, the user will be prompted.

=cut

has password => (
  is   => 'ro',
  isa  => 'Str',
  init_arg => undef,
  lazy => 1,
  default  => sub {
    my ($self) = @_;
    my $pw = $self->_credential('password') || $self->pause_cfg->{password};

    unless ($pw){
      my $uname = $self->username;
      $pw = $self->zilla->chrome->prompt_str(
        "PAUSE password for $uname: ",
        { noecho => 1 },
      );
    }

    return $pw;
  },
);

=attr pause_cfg_file

This is the name of the file containing your pause credentials.  It defaults
F<.pause>.  If you give a relative path, it is taken to be relative to
L</pause_cfg_dir>.

=cut

has pause_cfg_file => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { '.pause' },
);

=attr pause_cfg_dir

This is the directory for resolving a relative L</pause_cfg_file>.
It defaults to C<< File::HomeDir->my_home >>.

=cut

has pause_cfg_dir => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { require File::HomeDir; File::HomeDir::->my_home },
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
    require CPAN::Uploader;
    my $file = $self->pause_cfg_file;
    $file = File::Spec->catfile($self->pause_cfg_dir, $file)
      unless File::Spec->file_name_is_absolute($file);
    my $cfg = try {
      CPAN::Uploader->read_config_file($file)
    } catch {
      {};
    };
    return $cfg;
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

    # Load the module lazily
    require CPAN::Uploader;
    CPAN::Uploader->VERSION('0.103004');  # require HTTPS

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
