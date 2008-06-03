package Dist::Zilla::Plugin::PodWeaver;
use Moose;
with 'Dist::Zilla::Role::FileMunger';

sub munge_file {
  my ($self, $file) = @_;

  return $self->munge_pod($file)
    if $file->name =~ /\.pm$/i
    and ($file->name !~ m{/} or $file->name =~ m{^lib/});

  return;
}

sub munge_pod {
  my ($self, $file) = @_;
  require PPI;
  my $content = $file->content;
  my $doc = PPI::Document->new(\$content);
  return unless my $pod = $doc->find('PPI::Token::Pod');
  warn ">>$_<<\n" for @$pod;
  $doc->prune('PPI::Token::Pod');
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
