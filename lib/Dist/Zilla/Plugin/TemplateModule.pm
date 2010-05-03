package Dist::Zilla::Plugin::TemplateModule
# ABSTRACT: a simple module-from-template plugin
use Moose;
with 'Dist::Zilla::Role::ModuleMaker';

sub make_module {
  my ($self, $arg) = @_;

  ...
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
