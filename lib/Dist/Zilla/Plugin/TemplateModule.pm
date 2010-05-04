package Dist::Zilla::Plugin::TemplateModule;
# ABSTRACT: a simple module-from-template plugin
use Moose;
with qw(Dist::Zilla::Role::ModuleMaker Dist::Zilla::Role::TextTemplate);

use autodie;

use Data::Section 0.004 -setup; # fixed header_re
use Dist::Zilla::File::InMemory;

has template => (
  is  => 'ro',
  isa => 'Str',
  predicate => 'has_template',
);

sub make_module {
  my ($self, $arg) = @_;

  my $template;

  if ($self->has_template) {
    open my $fh, '<', $self->template;
    $template = do { local $/; <$fh> };
  } else {
    $template = ${ $self->section_data('Module.pm') };
  }

  my $content = $self->fill_in_string(
    $template,
    {
      name => $arg->{name},
    },
  );

  (my $filename = $arg->{name}) =~ s{::}{/}g;

  my $file = Dist::Zilla::File::InMemory->new({
    name    => "lib/$filename.pm",
    content => $content,
  });

  $self->add_file($file);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
__DATA__
__[ Module.pm ]__
use strict;
use warnings;
package {{ $name }};

1;
