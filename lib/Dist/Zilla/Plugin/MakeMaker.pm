package Dist::Zilla::Plugin::MakeMaker;
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileWriter';

use Dist::Zilla::File::InMemory;

use Text::Template;

my $template = <<'END_MAKEFILE';
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => '{{ $dist->name }}',
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

  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'Makefile.PL',
    content => $content,
  });

  return [ $file ];
}

1;
