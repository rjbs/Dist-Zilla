package Dist::Zilla::Plugin::MakeMaker;
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileWriter';
with 'Dist::Zilla::Role::TextTemplate';

use Dist::Zilla::File::InMemory;

my $template = <<'END_MAKEFILE';
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => '{{ $dist->name }}',
  AUTHOR       => '{{ $author_str }}',
  VERSION_FROM => "{{ (grep { /.pm$/ } @{$dist->files})[0] }}",
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => '{{ $dist->license->meta_yml_name }}') : ()),
  PREREQ_PM    => {
{{
      my $prereq = $dist->prereq;
      $OUT .= qq{    "$_" => '$prereq->{$_}',\n} for keys %$prereq;
      chomp $OUT;
      return '';
}}
  },
);
END_MAKEFILE

sub write_files {
  my ($self, $arg) = @_;

  my $content = $self->fill_in_string(
    $template,
    {
      dist       => \$arg->{dist},
      author_str => \quotemeta($arg->{dist}->authors->join(q{, })),
    },
  );

  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'Makefile.PL',
    content => $content,
  });

  return [ $file ];
}

1;
