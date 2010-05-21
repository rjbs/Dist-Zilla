package Dist::Zilla::MVP::RootSection;
use Moose;
extends 'Config::MVP::Section';

has '+name'    => (default => '_');

has '+aliases' => (default => sub { return { author => 'authors' } });

has '+multivalue_args' => (default => sub { [ qw(authors) ] });

after finalize => sub {
  my ($self) = @_;

  my $assembler = $self->sequence->assembler;
  my $preload   = $assembler->_core_preload;

  my $zilla = $assembler->zilla_class->new({
    %$preload,
    %{ $self->payload }
  });

  $assembler->set_zilla($zilla);
};

1;
