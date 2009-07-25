package Dist::Zilla::Config::INI;
use Moose;
with qw(Dist::Zilla::Config Dist::Zilla::Role::ConfigMVP);
# ABSTRACT: read in a dist.ini file

use Dist::Zilla::Util;
  use Config::INI::MVP::Reader;

=head1 DESCRIPTION

Dist::Zilla::Config reads in the F<dist.ini> file for a distribution.  It uses
L<Config::INI::MVP::Reader> to do most of the heavy lifting.  You may write
your own class to read your own config file format.  It is expected to return 
a hash reference to be used in constructing a new Dist::Zilla object.  The
"plugins" entry in the hashref should be an arrayref of plugin configuration
like this:

  $config->{plugins} = [
    [ $class_name => { ...config...} ],
    ...
  ];

=cut

has 'reader' => (
  is   => 'ro',
  isa  => 'Config::INI::MVP::Reader',
  init_arg => undef,
  required => 1,
  default  => sub {
    Config::INI::MVP::Reader->new({
      assembler => $_[0]->assembler,
    });
  },
);

sub default_filename { 'dist.ini' }

sub read_config {
  my ($self, $arg) = @_;
  my $config_file = $arg->{root}->file( $self->default_filename );
  my $x = $self->reader->read_file($config_file);

  warn Data::Dumper::Dumper({
    data_rv   => $x,
    assembler => $self->reader->assembler,
  });

  $self->config_from_mvp;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
