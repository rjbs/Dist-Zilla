package Dist::Zilla::Plugin::FakeRelease;
# ABSTRACT: fake plugin to test release

use Moose;
with 'Dist::Zilla::Role::Releaser';

use namespace::autoclean;

has user => (
  is   => 'ro',
  isa  => 'Str',
  required => 1,
  default  => 'AUTHORID',
);

around dump_config => sub {
  my $orig = shift;
  my $self = shift;

  my $config = $self->$orig;

  $config->{+__PACKAGE__} = { user => $self->user };

  return $config;
};

sub release {
  my $self = shift;

  for my $env (
    'DIST_ZILLA_FAKERELEASE_FAIL', # old
    'DZIL_FAKERELEASE_FAIL',       # new
  ) {
    $self->log_fatal("$env set, aborting") if $ENV{$env};
  }

  $self->log('Fake release happening (nothing was really done)');
}

__PACKAGE__->meta->make_immutable;
1;

=head1 SYNOPSIS

    [FakeRelease]
    user = CPANAUTHORID ; # optional.

=head1 DESCRIPTION

This plugin is a L<Releaser|Dist::Zilla::Role::Releaser> that does nothing. It
is directed to plugin authors, who may need a dumb release plugin to test their
shiny plugin implementing L<BeforeRelease|Dist::Zilla::Role::BeforeRelease>
and L<AfterRelease|Dist::Zilla::Role::AfterRelease>.

When this plugin does the release, it will just log a message and finish.

If you set the environment variable C<DZIL_FAKERELEASE_FAIL> to a true value,
the plugin will die instead of doing nothing. This can be useful for
authors wanting to test reliably that release failed.

You can optionally provide the 'user' parameter, which defaults to 'AUTHORID',
which will allow things that depend on this metadata
( Sometimes provided by L<UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN> ) to still work.
( For example: L<Dist::Zilla::Plugin::Twitter> )

=head1 SEE ALSO

Core Dist::Zilla plugins:
L<ConfirmRelease|Dist::Zilla::Plugin::ConfirmRelease>,
L<UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN>.

