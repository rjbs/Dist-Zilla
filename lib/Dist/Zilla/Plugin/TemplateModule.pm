package Dist::Zilla::Plugin::TemplateModule;
# ABSTRACT: a simple module-from-template plugin
use Moose;
with qw(Dist::Zilla::Role::ModuleMaker Dist::Zilla::Role::TextTemplate);

use Path::Tiny;

use namespace::autoclean;

use autodie;

use Sub::Exporter::ForMethods;
use Data::Section 0.200002 # encoding and bytes
  { installer => Sub::Exporter::ForMethods::method_installer },
  '-setup';
use Dist::Zilla::File::InMemory;

=head1 MINTING CONFIGURATION

This module is part of the standard configuration of the default L<Dist::Zilla>
Minting Profile, and all profiles that don't set a custom ':DefaultModuleMaker'
so you don't need to normally do anything to configure it.

  dzil new Some::Module
  # creates ./Some-Module/*
  # creates ./Some-Module/lib/Some/Module.pm

However, for those who wish to configure this ( or any subclasses ) this is
presently required:

  [TemplateModule / :DefaultModuleMaker]
  ; template  = SomeFile.pm

=head1 DESCRIPTION

This is a L<ModuleMaker|Dist::Zilla::Role::ModuleMaker> used for creating new
Perl modules files when minting a new dist with C<dzil new>.  It uses
L<Text::Template> (via L<Dist::Zilla::Role::TextTemplate>) to render a template
into a Perl module.  The template is given two variables for use in rendering:
C<$name>, the module name; and C<$dist>, the Dist::Zilla object.  The module is
always created as a file under F<./lib>.

By default, the template looks something like this:

  use strict;
  use warnings;
  package {{ $name }};

  1;

=attr template

The C<template> parameter may be given to the plugin to provide a different
filename, absolute or relative to the build/profile directory.

If this parameter is not specified, this module will use the boilerplate module
template included in this module.

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
    $template = path( $self->template )->slurp_utf8;
  } else {
    $template = ${ $self->section_data('Module.pm') };
  }

  my $content = $self->fill_in_string(
    $template,
    {
      dist => \($self->zilla),
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
1;
__DATA__
__[ Module.pm ]__
use strict;
use warnings;
package {{ $name }};

1;
