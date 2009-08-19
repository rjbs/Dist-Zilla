package Dist::Zilla::Config::Perl;
use Moose;
with qw(
  Dist::Zilla::Config
  Dist::Zilla::ConfigRole::Findable
  Dist::Zilla::ConfigRole::MVP
);
# ABSTRACT: the reader for dist.pl files

=head1 DESCRIPTION

Dist::Zilla::Config reads in the F<dist.pl> file for a distribution.  It uses
L<Config::MVP::Assembler> to do most of the heavy lifting, using the helpers
set up in L<Dist::Zilla::Role::ConfigMVP>.

=cut

sub default_extension { 'pl' }

sub read_config {
  my ($self, $arg) = @_;
  my $config_file = $arg->{root}->file( $self->filename_from_args($arg) );

  my $asm = $self->assembler;

  my @input = do $config_file;
  while (@input and ! ref $input[0]) {
    my ($key, $value) = (shift(@input), shift(@input));
    $asm->add_value($key => $value);
  }

  my $plugins = shift @input;

  confess "too much input" if @input;

  while (my ($ident, $arg) = splice @$plugins, 0, 2) {
    unless (ref $arg) {
      unshift @$plugins, $arg;
      $arg = [];
    }

    my ($moniker, $name) = ref $ident ? @$ident : (($ident) x 2);
    $asm->change_section($moniker, $name);
    my @to_iter = ref $arg eq 'HASH' ? %$arg : @$arg;
    while (my ($key, $value) = splice @to_iter, 0, 2) {
      $asm->add_value($key, $value);
    }
  }

  return $self->config_struct;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
