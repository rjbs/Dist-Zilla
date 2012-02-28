package Dist::Zilla::Prereqs;
# ABSTRACT: the prerequisites of a Dist::Zilla distribution
use Moose;
use Moose::Autobox;
use MooseX::Types::Moose qw(Bool HashRef);

use CPAN::Meta::Prereqs 2.101390;
use Hash::Merge::Simple ();
use Path::Class ();
use String::RewritePrefix;
use CPAN::Meta::Requirements;

use namespace::autoclean;

=head1 DESCRIPTION

Dist::Zilla::Prereqs is a subcomponent of Dist::Zilla.  The C<prereqs>
attribute on your Dist::Zilla object is a Dist::Zilla::Prereqs object, and is
responsible for keeping track of the distribution's prerequisites.

In fact, a Dist::Zilla::Prereqs object is just a thin layer over a
L<CPAN::Meta::Prereqs> object, stored in the C<cpan_meta_prereqs> attribute.

Almost everything this object does is proxied to the CPAN::Meta::Prereqs
object, so you should really read how I<that> works.

Dist::Zilla::Prereqs proxies the following methods to the CPAN::Meta::Prereqs
object:

=for :list
* finalize
* is_finalized
* requirements_for
* as_string_hash

=cut

has cpan_meta_prereqs => (
  is  => 'ro',
  isa => 'CPAN::Meta::Prereqs',
  init_arg => undef,
  default  => sub { CPAN::Meta::Prereqs->new },
  handles  => [ qw(
    finalize
    is_finalized
    requirements_for
    as_string_hash
  ) ],
);

=method register_prereqs

  $prereqs->register_prereqs(%prereqs);

  $prereqs->register_prereqs(\%arg, %prereqs);

This method adds new minimums to the prereqs object.  If a hashref is the first
arg, it may have entries for C<phase> and C<type> to indicate what kind of
prereqs are being registered.  (For more information on phase and type, see
L<CPAN::Meta::Spec>.)  For example, you might say:

  $prereqs->register_prereqs(
    { phase => 'test', type => 'recommends' },
    'Test::Foo' => '1.23',
    'XML::YZZY' => '2.01',
  );

If not given, phase and type default to runtime and requires, respectively.

=cut

sub register_prereqs {
  my $self = shift;
  my $arg  = ref($_[0]) ? shift(@_) : {};
  my %prereq = @_;

  my $phase = $arg->{phase} || 'runtime';
  my $type  = $arg->{type}  || 'requires';

  my $req = $self->requirements_for($phase, $type);

  while (my ($package, $version) = each %prereq) {
    $req->add_string_requirement($package, $version);
  }

  return;
}

__PACKAGE__->meta->make_immutable;
1;
