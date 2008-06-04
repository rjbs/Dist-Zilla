package Dist::Zilla::Plugin::CreditTaker;
# ABSTRACT: add 'built by D::Z' to all your modules
use Moose;
with 'Dist::Zilla::Role::FileMunger';

sub munge_file {
  my ($self, $file) = @_;

  return unless $file->name =~ /\.pm/;

  my $content = $file->content;
  return if $content =~ /\A# built by Dist::Zilla/;

  my $credit = "# built by Dist::Zilla " . Dist::Zilla->VERSION . "\n";
  $content =~ s/\A/$credit/;

  $file->content($content);
  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
