package Dist::Zilla::Plugin::MakeMaker;
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileWriter';

use Text::Template;

my $template = <<'END_MAKEFILE';
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => {{ $dist->name }},
  VERSION_FROM => "{{ (grep { /.pm$/ } @{$dist->files})[0] }}",
);
END_MAKEFILE

sub write_files {
  my ($self, $arg) = @_;

  my $content = Text::Template::fill_in_string(
    $template,
    HASH       => { dist => \$arg->{dist} },
    DELIMITERS => [ qw(  {{  }}  ) ],
  );

  $self->write_content_to($content, $arg->{build_root}->file('Makefile.PL'));
  $arg->{manifest}->push('Makefile.PL');
}

1;
