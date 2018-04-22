package Dist::Zilla::Plugin::ModuleShareDirs;
# ABSTRACT: install a directory's contents as module-based "ShareDir" content

use Moose;

use Dist::Zilla::Dialect;

use namespace::autoclean;

=head1 SYNOPSIS

In your F<dist.ini>:

  [ModuleShareDirs]
  Foo::Bar = shares/foo_bar
  Foo::Baz = shares/foo_baz

=cut

has _module_map => (
  is   => 'ro',
  isa  => 'HashRef',
  default => sub { {} },
);

sub find_files ($self) {
  my $modmap = $self->_module_map;
  my @files;

  for my $mod ( keys %$modmap ) {
    my $dir = $modmap->{$mod};
    my @mod_files = grep { index($_->name, "$dir/") == 0 }
      $self->zilla->files->@*;
    push @files, @mod_files;
  }

  return \@files;
}

sub share_dir_map ($self) {
  my $modmap = $self->_module_map;

  return unless keys %$modmap;
  return { module => $modmap };
}

around BUILDARGS => sub ($orig, $class, @rest) {
  my $args = $class->$orig(@rest);
  my %copy = %$args;

  my $zilla = delete $copy{zilla};
  my $name  = delete $copy{plugin_name};

  return {
    zilla => $zilla,
    plugin_name => $name,
    _module_map => \%copy,
  }
};

with 'Dist::Zilla::Role::ShareDir';
__PACKAGE__->meta->make_immutable;
1;
