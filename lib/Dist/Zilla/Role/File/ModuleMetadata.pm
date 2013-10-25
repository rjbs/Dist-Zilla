package Dist::Zilla::Role::File::ModuleMetadata;
# ABSTRACT: a role for files that are analyzed with Module::Metadata
use Moose::Role;
use Moose::Util::TypeConstraints;
use Module::Metadata;

has module_metadata => (
  is => 'ro', isa => class_type('Module::Metadata'),
  clearer => '_clear_module_metadata',
  lazy => 1,
  builder => '_build_module_metadata',
);

sub _build_module_metadata {
  my ($self) = @_;

  my $binmode = $self->encoding eq 'bytes' ? ':raw' : sprintf ':encoding(%s)', $self->encoding;
  open my $fh, '<'.$binmode, \$self->encoded_content or confess("cannot open scalar fh: $!");
  Module::Metadata->new_from_handle($fh, $self->name);
}

after [qw(content encoded_content)] => sub {
  my ($self) = @_;
  $self->_clear_module_metadata if @_ > 1;    # content is updated
};

1;
__END__

=pod

=head1 DESCRIPTION

This role provides a central location for managing a L<Module::Metadata>
object for the corresponding file.

Internally, this role caches the object, refreshing it after the file's
content is changed.

=method module_metadata

The accessor for the L<Module::Metadata> object

=cut
