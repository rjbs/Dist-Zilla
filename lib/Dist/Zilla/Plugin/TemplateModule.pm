package Dist::Zilla::Plugin::TemplateModule;
# ABSTRACT: a simple module-from-template plugin
use Moose;
with qw(Dist::Zilla::Role::ModuleMaker Dist::Zilla::Role::TextTemplate);

use autodie;

use Data::Section 0.004 -setup; # fixed header_re
use Dist::Zilla::File::InMemory;

=head1 DESCRIPTION

This is a L<ModuleMaker|Dist::Zilla::Role::ModuleMaker> used for creating new
Perl modules files when minting a new dist with C<dzil new>.  It uses
L<Text::Template> (via L<Dist::Zilla::Role::TextTemplate>) to render a template
into a Perl module.  The only variable provided to the template is C<$name>,
the module name.  The module is always created as a file under F<./lib>.

By default, the template looks something like this:

  use strict;
  use warnings;
  package {{ $name }};

  1;

=attr template

The C<template> parameter may be given to the plugin to provide a different
filename, absolute or relative to the build root.

=cut

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

    # Win32
    binmode $fh, ':raw';
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
