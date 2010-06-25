use strict;
use warnings;
package Dist::Zilla::App::Command::input;
# ABSTRACT: demonstrate how input chrome works
use Dist::Zilla::App -command;

sub abstract { 'demonstrate chrome input methods' }

sub opt_spec {
}

sub execute {
  my ($self, $opt, $arg) = @_;

  my $zilla = $self->zilla;

  $zilla->log("beginning input tests");

  for my $default (undef, 'y', 'n') {
    my $yn = $zilla->chrome->prompt_yn(
      "yes or no?",
      defined($default) ? { default => $default } : ()
    );

    $zilla->log([ "yes or no: %s", $yn ]);
  }

  $zilla->chrome->prompt_any_key;
  $zilla->chrome->prompt_any_key("smack one");
}

1;
