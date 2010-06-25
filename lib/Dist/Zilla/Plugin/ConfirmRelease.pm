package Dist::Zilla::Plugin::ConfirmRelease;
# ABSTRACT: prompt for confirmation before releasing

use ExtUtils::MakeMaker ();

use Moose;
with 'Dist::Zilla::Role::BeforeRelease';

sub before_release {
  my ($self, $tgz) = @_;

  my $prompt = "*** Preparing to upload $tgz to CPAN ***\n"
             . "Do you want to continue the release process?";

  my $default = exists $ENV{DZIL_CONFIRMRELEASE_DEFAULT}
              ? $ENV{DZIL_CONFIRMRELEASE_DEFAULT}
              : 0;

  my $confirmed = $self->zilla->chrome->prompt_yn(
    $prompt,
    { default => $default }
  );

  $self->log_fatal("Aborting release") unless $confirmed;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 DESCRIPTION

This plugin prompts the author whether or not to continue before releasing
the distribution to CPAN.  It gives authors a chance to abort before
they upload.

The default is "no", but you can set the environment variable
C<DZIL_CONFIRMRELEASE_DEFAULT> to "yes" if you just want to hit enter to
release.

This plugin uses C<ExtUtils::MakeMaker::prompt()>, so setting
C<PERL_MM_USE_DEFAULT> to a true value will accept the default without
prompting.
