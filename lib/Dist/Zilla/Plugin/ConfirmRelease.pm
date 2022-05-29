package Dist::Zilla::Plugin::ConfirmRelease;
# ABSTRACT: prompt for confirmation before releasing

use Moose;
with 'Dist::Zilla::Role::BeforeRelease';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

sub before_release ($self, $tgz) {
  my $releasers = join q{, },
                  map {; $_->plugin_name }
                  @{ $self->zilla->plugins_with(-Releaser) };

  $self->log("*** Preparing to release $tgz with $releasers ***");
  my $prompt = "Do you want to continue the release process?";

  my $default = exists $ENV{DZIL_CONFIRMRELEASE_DEFAULT}
              ? $ENV{DZIL_CONFIRMRELEASE_DEFAULT}
              : 0;

  my $confirmed = $self->zilla->chrome->prompt_yn(
    $prompt,
    { default => $default }
  );

  $self->log_fatal("Aborting release") unless $confirmed;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 DESCRIPTION

This plugin prompts the author whether or not to continue before releasing
the distribution to CPAN.  It gives authors a chance to abort before
they upload.

The default is "no", but you can set the environment variable
C<DZIL_CONFIRMRELEASE_DEFAULT> to "yes" if you just want to hit enter to
release.
