package Dist::Zilla::Config::INI;
use Moose;
with qw(
  Dist::Zilla::Config
  Dist::Zilla::ConfigRole::Findable
  Dist::Zilla::ConfigRole::MVP
);
# ABSTRACT: the reader for dist.ini files

use Dist::Zilla::Util;
use Config::INI::MVP::Reader;

=head1 DESCRIPTION

Dist::Zilla::Config reads in the F<dist.ini> file for a distribution.  It uses
L<Config::INI::MVP::Reader> to do most of the heavy lifting, using the helpers
set up in L<Dist::Zilla::Role::ConfigMVP>.

=cut

# Clearly this should be an attribute with a builder blah blah blah. -- rjbs,
# 2009-07-25
sub default_filename { 'dist.ini' }
sub filename         { $_[0]->default_filename }

sub can_be_found {
  my ($self, $arg) = @_;

  my $config_file = $arg->{root}->file( $self->filename );
  return -r "$config_file" and -f _;
}

sub read_config {
  my ($self, $arg) = @_;
  my $config_file = $arg->{root}->file( $self->filename );

  my $ini = Config::INI::MVP::Reader->new({ assembler => $self->assembler });
  $ini->read_file($config_file);

  return $self->config_struct;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
