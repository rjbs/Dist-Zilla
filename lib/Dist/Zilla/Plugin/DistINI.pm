package Dist::Zilla::Plugin::DistINI;
# ABSTRACT: a plugin to add a dist.ini to newly-minted dists

use Moose;
with qw(Dist::Zilla::Role::FileGatherer);

use Dist::Zilla::Dialect;

use Dist::Zilla::File::FromCode;

use MooseX::Types::Moose qw(ArrayRef Str);
use Dist::Zilla::Path;

use namespace::autoclean;

=head1 DESCRIPTION

This plugins produces a F<dist.ini> file in a new dist, specifying the required
core attributes from the dist being minted.

This plugin is dead simple and pretty stupid, but should get better as dist
minting facilities improve.  For example, it will not specify any plugins.

In the meantime, you may be happier with a F<dist.ini> template.

=attr append_file

This parameter may be a filename in the profile's directory to append to the
generated F<dist.ini> with things like plugins.  In other words, if your make
this file, called F<plugins.ini>:

  [@Basic]
  [NextRelease]
  [@Git]

...and your F<profile.ini> includes:

  [DistINI]
  append_file = plugins.ini

...then the generated C<dist.ini> in a newly-minted dist will look something
like this:

  name    = My-New-Dist
  author  = E. Xavier Ample <example@example.com>
  license = Perl_5
  copyright_holder = E. Xavier Ample
  copyright_year   = 2010

  [@Basic]
  [NextRelease]
  [@Git]

=cut

sub mvp_multivalue_args { qw(append_file) }

has append_file => (
  is  => 'ro',
  isa => ArrayRef[ Str ],
  default => sub { [] },
);

sub gather_files {
  my ($self, $arg) = @_;

  my $zilla = $self->zilla;

  my $postlude = '';

  for (@{ $self->append_file }) {
    my $fn = $self->zilla->root->child($_);

    $postlude .= path($fn)->slurp_utf8;
  }

  my $code = sub {
    my @core_attrs = qw(name authors copyright_holder);

    my $license = ref $zilla->license;
    if ($license =~ /^Software::License::(.+)$/) {
      $license = $1;
    } else {
      $license = "=$license";
    }

    my $content = '';
    $content .= sprintf "name    = %s\n", $zilla->name;
    $content .= sprintf "author  = %s\n", $_ for @{ $zilla->authors };
    $content .= sprintf "license = %s\n", $license;
    $content .= sprintf "copyright_holder = %s\n", $zilla->copyright_holder;
    $content .= sprintf "copyright_year   = %s\n", (localtime)[5] + 1900;
    $content .= "\n";

    $content .= $postlude;
  };

  my $file = Dist::Zilla::File::FromCode->new({
    name => 'dist.ini',
    code => $code,
  });

  $self->add_file($file);
}

__PACKAGE__->meta->make_immutable;
1;
