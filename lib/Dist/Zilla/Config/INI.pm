package Dist::Zilla::Config::INI;
use Moose;
with 'Dist::Zilla::Config';
# ABSTRACT: read in a dist.ini file

use Dist::Zilla::Util;

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

sub default_filename { 'dist.ini' }

has 'reader' => (
  is   => 'ro',
  isa  => 'Config::INI::Reader',
  init_arg => undef,
  required => 1,
  default  => sub { Dist::Zilla::Config::INI::Reader->new },
);

sub read_config {
  my ($self, $arg) = @_;
  my $config_file = $arg->{root}->file( $self->default_filename );
  my $data = $self->reader->read_file($config_file);
  $self->struct_to_config($data);
}

BEGIN {
  package
    Dist::Zilla::Config::INI::Reader;
  use base 'Config::INI::MVP::Reader';

  sub multivalue_args { qw(author) }

  sub _expand_package {
    my $str = Dist::Zilla::Util->expand_config_package_name($_[1]);
    return $str;
  }
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
