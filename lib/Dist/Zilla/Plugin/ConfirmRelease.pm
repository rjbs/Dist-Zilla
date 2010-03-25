package Dist::Zilla::Plugin::ConfirmRelease;
# ABSTRACT: prompt for confirmation before releasing

use ExtUtils::MakeMaker ();

use Moose;
with 'Dist::Zilla::Role::BeforeRelease';

sub before_release {
  my $self = shift;
  my $dist = $self->zilla->name . "-" . $self->zilla->version;
  
  my $prompt =  "\n*** Preparing to upload $dist to CPAN ***\n\n" .
                "Do you want to continue the release process? (yes/no)";

  my $default = exists $ENV{DZIL_CONFIRMRELEASE_DEFAULT} 
              ? $ENV{DZIL_CONFIRMRELEASE_DEFAULT} 
              : "no" ;

  my $answer = ExtUtils::MakeMaker::prompt($prompt,$default);
    
  if ( $answer !~ /^y/i ) {
    $self->log_fatal("Aborting release");
  }
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
C<DZIL_CONFIRM_RELEASE> to "yes" if you just want to hit enter to release.

This plugin uses C<ExtUtils::MakeMaker::prompt()>, so setting
C<PERL_MM_USE_DEFAULT> to a true value will accept the default without
prompting.
