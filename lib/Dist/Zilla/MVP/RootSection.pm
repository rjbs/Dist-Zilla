package Dist::Zilla::MVP::RootSection;
use Moose;
extends 'Config::MVP::Section';
# ABSTRACT: a standard section in Dist::Zilla's configuration sequence

use namespace::autoclean;

=head1 DESCRIPTION

This is a subclass of L<Config::MVP::Section>, used as the starting section by
L<Dist::Zilla::MVP::Assembler::Zilla>.  It has a number of useful defaults, as
well as a C<zilla> attribute which will, after section finalization, contain a
Dist::Zilla object with which subsequent plugin sections may register.

Those useful defaults are:

=for :list
* name defaults to _
* aliases defaults to { author => 'authors' }
* multivalue_args defaults to [ 'authors' ]

=cut

use MooseX::LazyRequire;
use MooseX::SetOnce;
use Moose::Util::TypeConstraints;

has '+name'    => (default => '_');

has '+aliases' => (default => sub { return { author => 'authors' } });

has '+multivalue_args' => (default => sub { [ qw(authors) ] });

has zilla => (
  is     => 'ro',
  isa    => class_type('Dist::Zilla'),
  traits => [ qw(SetOnce) ],
  writer => 'set_zilla',
  lazy_required => 1,
);

after finalize => sub {
  my ($self) = @_;

  my $assembler = $self->sequence->assembler;

  my %payload = %{ $self->payload };

  my %dzil;
  $dzil{$_} = delete $payload{":$_"} for grep { s/\A:// } keys %payload;

  my $zilla = $assembler->zilla_class->new( \%payload );

  if (defined $dzil{version}) {
    Dist::Zilla::Util->_assert_loaded_class_version_ok(
      'Dist::Zilla',
      $dzil{version},
    );
  }

  $self->set_zilla($zilla);
};

__PACKAGE__->meta->make_immutable;
1;
