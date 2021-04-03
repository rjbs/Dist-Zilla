package Dist::Zilla::Plugin::ExtraTests;
# ABSTRACT: rewrite ./xt tests to ./t tests with skips

use Moose;
with 'Dist::Zilla::Role::FileMunger';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

=head1 DESCRIPTION

This plugin rewrites tests found in the following directories:

  ./xt/author  - tests for author testing (env AUTHOR_TESTING is true)
  ./xt/release - tests for pre-release testers (env RELEASE_TESTING is true)
  ./xt/smoke   - tests for automated testers (env AUTOMATED_TESTING is true)

The tests are renamed and moved to F<./t>, and they are rewritten to include
some simple Perl code to skip all included tests if the correct env vars are
not set.

=cut

sub munge_file {
  my ($self, $file) = @_;

  return unless $file->name =~ m{\Axt/(smoke|author|release)/.+\.t\z};
  my $method = "_rewrite_$1\_test";

  $self->log("rewriting $1 test " . $file->name);

  $self->$method($file);
}

sub _rewrite_smoke_test {
  my ($self, $file) = @_;
  $self->_rewrite($file, 'AUTOMATED_TESTING', '"smoke bot" testing');
}

sub _rewrite_author_test {
  my ($self, $file) = @_;
  $self->_rewrite($file, 'AUTHOR_TESTING', 'testing by the author');
}

sub _rewrite_release_test {
  my ($self, $file) = @_;
  $self->_rewrite($file, 'RELEASE_TESTING', 'release candidate testing');
}

sub _rewrite {
  my ($self, $file, $env, $msg) = @_;

  my $name = $file->name =~ s{^xt/([^/]+)/}{t/$1-}r;

  $file->name($name);

  my @lines = split /\n/, $file->content;
  my $after = $lines[0] =~ /\A#!/ ? 1 : 0;
  splice @lines, $after, 0, qq|
BEGIN {
  unless (\$ENV{$env}) {
    print qq{1..0 # SKIP these tests are for $msg\\n};
    exit
  }
}
|;

  $file->content(join "\n", @lines, '');
}

__PACKAGE__->meta->make_immutable;
1;
