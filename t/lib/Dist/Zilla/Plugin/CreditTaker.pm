package Dist::Zilla::Plugin::CreditTaker;
use Moose;
with 'Dist::Zilla::Role::FileMunger';

sub munge_file {
  my ($self, $arg) = @_;
  return unless $arg->{to} =~ /\.pm/;

  return if $arg->{content} =~ /\A# built by Dist::Zilla/;

  my $credit = "# build by Dist::Zilla " . Dist::Zilla->VERSION . "\n";
  $arg->{content} =~ s/\A/$credit/;
}

1;
