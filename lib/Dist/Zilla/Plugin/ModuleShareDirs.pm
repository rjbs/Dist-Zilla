package Dist::Zilla::Plugin::ModuleShareDirs;
# ABSTRACT: install a directory's contents as module-based "ShareDir" content

use Moose;
with 'Dist::Zilla::Role::ShareDir';

use namespace::autoclean;

use Moose::Autobox;

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

sub find_files {
  my ($self) = @_;
  my $modmap = $self->_module_map;
  my @files;

  for my $mod ( keys %$modmap ) {
    my $dir = $modmap->{$mod};
    my $mod_files = $self->zilla->files->grep(
      sub { index($_->name, "$dir/") == 0 }
    );
    push @files, @$mod_files;
  }

  return \@files;
}

sub share_dir_map {
  my ($self) = @_;
  my $modmap = $self->_module_map;

  return unless keys %$modmap;
  return { module => $modmap };
}

sub BUILDARGS {
  my ($class, @arg) = @_;
  my %copy = ref $arg[0] ? %{$arg[0]} : @arg;

  my $zilla = delete $copy{zilla};
  my $name  = delete $copy{plugin_name};

  return {
    zilla => $zilla,
    plugin_name => $name,
    _module_map => \%copy,
  }
}

around dump_config => sub {
  my $orig = shift;
  my $self = shift;

  my $config = $self->$orig;

  $config->{+__PACKAGE__} = { module_map => $self->_module_map };

  return $config;
};

__PACKAGE__->meta->make_immutable;
1;
