package Dist::Zilla::Plugin::NextRelease;
# ABSTRACT: update the next release number in your changelog

use Moose;
with (
  'Dist::Zilla::Role::FileMunger',
  'Dist::Zilla::Role::TextTemplate',
  'Dist::Zilla::Role::AfterRelease',
);

use Dist::Zilla::Dialect;

use namespace::autoclean;

use Dist::Zilla::Path;
use Moose::Util::TypeConstraints;
use List::Util 'first';
use String::Formatter 0.100680 stringf => {
  -as => '_format_version',

  input_processor => 'require_single_input',
  string_replacer => 'method_replace',
  codes => {
    v => sub { $_[0]->zilla->version },
    d => sub {
      require DateTime;
      DateTime->VERSION('0.44'); # CLDR fixes

      DateTime->from_epoch(epoch => $^T, time_zone => $_[0]->time_zone)
              ->format_cldr($_[1]),
    },
    t => sub { "\t" },
    n => sub { "\n" },
    E => sub { $_[0]->_user_info('email') },
    U => sub { $_[0]->_user_info('name')  },
    T => sub { $_[0]->zilla->is_trial
                   ? ($_[1] // '-TRIAL') : '' },
    V => sub { $_[0]->zilla->version
                . ($_[0]->zilla->is_trial
                   ? ($_[1] // '-TRIAL') : '') },
    P => sub {
      my $releaser = first { $_->can('cpanid') } @{ $_[0]->zilla->plugins_with('-Releaser') };
      $_[0]->log_fatal('releaser doesn\'t provide cpanid, but %P used') unless $releaser;
      $releaser->cpanid;
    },
  },
};

our $DEFAULT_TIME_ZONE = 'local';
has time_zone => (
  is => 'ro',
  isa => 'Str', # should be more validated later -- apocal
  default => $DEFAULT_TIME_ZONE,
);

has format => (
  is  => 'ro',
  isa => 'Str', # should be more validated Later -- rjbs, 2008-06-05
  default => '%-9v %{yyyy-MM-dd HH:mm:ssZZZZZ VVVV}d%{ (TRIAL RELEASE)}T',
);

has filename => (
  is  => 'ro',
  isa => 'Str',
  default => 'Changes',
);

has update_filename => (
  is  => 'ro',
  isa => 'Str',
  lazy    => 1,
  default => sub { $_[0]->filename },
);

has user_stash => (
  is      => 'ro',
  isa     => 'Str',
  default => '%User'
);

has _user_stash_obj => (
  is       => 'ro',
  isa      => maybe_type( class_type('Dist::Zilla::Stash::User') ),
  lazy     => 1,
  init_arg => undef,
  default  => sub { $_[0]->zilla->stash_named( $_[0]->user_stash ) },
);

sub _user_info {
  my ($self, $field) = @_;

  my $stash = $self->_user_stash_obj;

  $self->log_fatal([
    "You must enter your %s in the [%s] section in ~/.dzil/config.ini",
    $field, $self->user_stash
  ]) unless $stash and defined(my $value = $stash->$field);

  return $value;
}

sub section_header {
  my ($self) = @_;

  return _format_version($self->format, $self);
}

has _original_changes_content => (
  is  => 'rw',
  isa => 'Str',
  init_arg => undef,
);

sub munge_files {
  my ($self) = @_;

  my ($file) = grep { $_->name eq $self->filename } @{ $self->zilla->files };
  $self->log_fatal([ 'failed to find %s in the distribution', $self->filename ]) if not $file;

  # save original unmunged content, for replacing back in the repo later
  my $content = $self->_original_changes_content($file->content);

  $content = $self->fill_in_string(
    $content,
    {
      dist    => \($self->zilla),
      version => \($self->zilla->version),
      NEXT    => \($self->section_header),
    },
  );

  $self->log_debug([ 'updating contents of %s in memory', $file->name ]);
  $file->content($content);
}

# new release is part of distribution history, let's record that.
sub after_release {
  my ($self) = @_;
  my $filename = $self->filename;
  my ($gathered_file) = grep { $_->name eq $filename } @{ $self->zilla->files };
  $self->log_fatal("failed to find $filename in the distribution") if not $gathered_file;
  my $iolayer = sprintf(":raw:encoding(%s)", $gathered_file->encoding);

  # read original changelog
  my $content = $self->_original_changes_content;

  # add the version and date to file content
  my $delim  = $self->delim;
  my $header = $self->section_header;
  $content =~ s{ (\Q$delim->[0]\E \s*) \$NEXT (\s* \Q$delim->[1]\E) }
               {$1\$NEXT$2\n\n$header}xs;

  my $update_fn = $self->update_filename;
  $self->log_debug([ 'updating contents of %s on disk', $update_fn ]);

  # and finally rewrite the changelog on disk
  path($update_fn)->spew({binmode => $iolayer}, $content);
}

__PACKAGE__->meta->make_immutable;
1;

=head1 SYNOPSIS

In your F<dist.ini>:

  [NextRelease]

In your F<Changes> file:

  {{$NEXT}}


=head1 DESCRIPTION

Tired of having to update your F<Changes> file by hand with the new
version and release date / time each time you release your distribution?
Well, this plugin is for you.

Add this plugin to your F<dist.ini>, and the following to your
F<Changes> file:

  {{$NEXT}}

The C<NextRelease> plugin will then do 2 things:

=over 4

=item * At build time, this special marker will be replaced with the
version and the build date, to form a standard changelog header. This
will be done to the in-memory file - the original F<Changes> file won't
be updated.

=item * After release (when running C<dzil release>), since the version
and build date are now part of your dist's history, the real F<Changes>
file (not the in-memory one) will be updated with this piece of
information.

=back

The module accepts the following options in its F<dist.ini> section:

=begin :list

= filename
the name of your changelog file;  defaults to F<Changes>

= update_filename
the file to which to write an updated changelog to; defaults to the C<filename>

= format
sprintf-like string used to compute the next value of C<{{$NEXT}}>;
defaults to C<%-9v %{yyyy-MM-dd HH:mm:ss VVVV}d>

= time_zone
the timezone to use when generating the date;  defaults to I<local>

= user_stash
the name of the stash where the user's name and email address can be found;
defaults to C<%User>

=end :list

The module allows the following sprintf-like format codes in the C<format>:

=begin :list

= C<%v>
The distribution version

= C<%{-TRIAL}T>
Expands to -TRIAL (or any other supplied string) if this
is a trial release, or the empty string if not.  A bare C<%T> means
C<%{-TRIAL}T>.

= C<%{-TRIAL}V>
Equivalent to C<%v%{-TRIAL}T>, to allow for the application of modifiers such
as space padding to the entire version string produced.

= C<%{CLDR format}d>
The date of the release.  You can use any CLDR format supported by
L<DateTime>.  You must specify the format; there is no default.

= C<%U>
The name of the user making this release (from C<user_stash>).

= C<%E>
The email address of the user making this release (from C<user_stash>).

= C<%P>
The CPAN (PAUSE) id of the user making this release (from -Releaser plugins;
see L<[UploadToCPAN]|Dist::Zilla::Plugin::UploadToCPAN/username>).

= C<%n>
A newline

= C<%t>
A tab

=end :list

=head1 SEE ALSO

Core Dist::Zilla plugins:
L<AutoVersion|Dist::Zilla::Plugin::AutoVersion>,
L<PkgVersion|Dist::Zilla::Plugin::PkgVersion>,
L<PodVersion|Dist::Zilla::Plugin::PodVersion>.

Dist::Zilla roles:
L<AfterRelease|Dist::Zilla::Plugin::AfterRelease>,
L<FileMunger|Dist::Zilla::Role::FileMunger>,
L<TextTemplate|Dist::Zilla::Role::TextTemplate>.
