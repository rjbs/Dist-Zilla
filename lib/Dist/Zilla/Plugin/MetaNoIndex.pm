package Dist::Zilla::Plugin::MetaNoIndex;
# ABSTRACT: Stop CPAN from indexing stuff

use Moose;
with 'Dist::Zilla::Role::MetaProvider';

use Dist::Zilla::Dialect;

use namespace::autoclean;

=encoding utf8

=head1 SYNOPSIS

In your F<dist.ini>:

  [MetaNoIndex]

  directory = t/author
  directory = examples

  file = lib/Foo.pm

  package = My::Module

  namespace = My::Module

=head1 DESCRIPTION

This plugin allows you to prevent PAUSE/CPAN from indexing files you don't
want indexed. This is useful if you build test classes or example classes
that are used for those purposes only, and are not part of the distribution.
It does this by adding a C<no_index> block to your F<META.json> (or
F<META.yml>) file in your distribution.

=for Pod::Coverage mvp_aliases mvp_multivalue_args

=cut

my %ATTR_ALIAS = (
  directories => [ qw(directory dir folder) ],
  files       => [ qw(file) ],
  packages    => [ qw(package class module) ],
  namespaces  => [ qw(namespace) ],
);

sub mvp_aliases {
  my %alias_for;

  for my $key (keys %ATTR_ALIAS) {
    $alias_for{ $_ } = $key for @{ $ATTR_ALIAS{$key} };
  }

  return \%alias_for;
}

sub mvp_multivalue_args { return keys %ATTR_ALIAS }

=attr directories

Exclude folders and everything in them, for example: F<author.t>

Aliases: C<folder>, C<dir>, C<directory>

=attr files

Exclude a specific file, for example: F<lib/Foo.pm>

Alias: C<file>

=attr packages

Exclude by package name, for example: C<My::Package>

Aliases: C<class>, C<module>, C<package>

=attr namespaces

Exclude everything under a specific namespace, for example: C<My::Package>

Alias: C<namespace>

B<NOTE:> This will not exclude the package C<My::Package>, only everything
under it like C<My::Package::Foo>.

=cut

for my $attr (keys %ATTR_ALIAS) {
  has $attr => (
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    init_arg  => $attr,
    predicate => "_has_$attr",
  );
}

=method metadata

Returns a reference to a hash containing the distribution's no_index metadata.

=cut

sub metadata {
  my $self = shift;
  return {
    no_index => {
      map  {; my $reader = $_->[0];  ($_->[1] => [ sort @{ $self->$reader } ]) }
      grep {; my $pred   = "_has_$_->[0]"; $self->$pred }
      map  {; [ $_ => $ATTR_ALIAS{$_}[0] ] }
      keys %ATTR_ALIAS
    }
  };
}

__PACKAGE__->meta->make_immutable;
1;

=head1 SEE ALSO

Dist::Zilla roles: L<MetaProvider|Dist::Zilla::Role::MetaProvider>.

=cut
