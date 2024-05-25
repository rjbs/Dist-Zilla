use strict;
use warnings;
use Test::More 0.88 tests => 17;

use File::Spec ();
use Test::DZil qw(Builder simple_ini);
use Test::Fatal qw(exception);

#---------------------------------------------------------------------
# Install a fake upload_file method for testing purposes:
sub Dist::Zilla::Plugin::UploadToCPAN::_Uploader::upload_file {
  my ($self, $archive) = @_;

  $self->log("PAUSE $_ is $self->{$_}") for qw(user password);
  $self->log("Uploading $archive") if -f $archive;
}

#---------------------------------------------------------------------
# Create a Builder with a simple configuration:
sub build_tzil {
  Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini('GatherDir', @_),
      },
    },
  );
}

#---------------------------------------------------------------------
# Set responses for the username and password prompts:
sub set_responses {
  my ($zilla, $username, $pw) = @_;
  $zilla->chrome->set_response_for('PAUSE username: ', $username);
  $zilla->chrome->set_response_for("PAUSE password for $username: ", $pw);
}

#---------------------------------------------------------------------
# Pass invalid upload_uri to UploadToCPAN as an extra precaution,
# and don't let it look for ~/.pause:
my %safety_first = (qw(upload_uri http://bogus.example.com/do/not/upload/),
                    pause_cfg_file => File::Spec->devnull);

#---------------------------------------------------------------------
# config from %PAUSE stash in dist.ini:
{
  my $tzil = build_tzil(
    [ UploadToCPAN => { %safety_first } ],
    'FakeRelease',
    [ '%PAUSE' => {qw(
      username  user
      password  password
    )}],
  );

  $tzil->release;

  my $msgs = $tzil->log_messages;

  ok(grep({ /PAUSE user is user/ } @$msgs), "read username");
  ok(grep({ /PAUSE password is password/ } @$msgs), "read password");
  ok(grep({ /Uploading.*DZT-Sample/ } @$msgs), "uploaded archive");
  ok(
    grep({ /fake release happen/i } @$msgs),
    "releasing continues after upload",
  );
}

#---------------------------------------------------------------------
# Config from user input:
{
  my $tzil = build_tzil(
    [ UploadToCPAN => { %safety_first } ],
    'FakeRelease',
  );

  set_responses($tzil, qw(user password));

  $tzil->release;

  my $msgs = $tzil->log_messages;

  ok(grep({ /PAUSE user is user/ } @$msgs), "entered username");
  ok(grep({ /PAUSE password is password/ } @$msgs), "entered password");
  ok(grep({ /Uploading.*DZT-Sample/ } @$msgs), "uploaded archive manually");
  ok(
    grep({ /fake release happen/i } @$msgs),
    "releasing continues after manual upload",
  );
}

#---------------------------------------------------------------------
# No config at all:
{
  my $tzil = build_tzil(
    'FakeRelease',
    [ UploadToCPAN => { %safety_first } ],
  );

  # Pretend user just hits Enter at the prompts:
  set_responses($tzil, '', '');

  like( exception { $tzil->release },
        qr/No username was provided/,
        "release without credentials fails");

  my $msgs = $tzil->log_messages;

  ok(grep({ /No username was provided/} @$msgs), "insist on username");
  ok(!grep({ /Uploading.*DZT-Sample/ } @$msgs), "no upload without credentials");
  ok(
    !grep({ /fake release happen/i } @$msgs),
    "no release without credentials"
  );
}

#---------------------------------------------------------------------
# No config at all, but enter username:
{
  my $tzil = build_tzil(
    'FakeRelease',
    [ UploadToCPAN => { %safety_first } ],
  );

  # Pretend user just hits Enter at the password prompt:
  set_responses($tzil, 'user', '');

  like( exception { $tzil->release },
        qr/No password was provided/,
        "release without password fails");

  my $msgs = $tzil->log_messages;

  ok(grep({ /No password was provided/} @$msgs), "insist on password");
  ok(!grep({ /Uploading.*DZT-Sample/ } @$msgs), "no upload without password");
  ok(
    !grep({ /fake release happen/i } @$msgs),
    "no release without password"
  );
}

# Config from dist.ini
{
  my $tzil = build_tzil(
    'FakeRelease',
    [ UploadToCPAN => {
        %safety_first,
        username => 'me',
        password => 'ohhai',
      }
    ],
  );

  like( exception { $tzil->release },
        qr/Couldn't figure out password/,
        "password set in dist.ini is ignored");
}
