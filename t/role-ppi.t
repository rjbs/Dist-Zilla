use strict;
use warnings;

use Test::More;

use Dist::Zilla::File::InMemory;

{
  package DZT::PPIUser;
  use Moose;
  with 'Dist::Zilla::Role::PPI';
}

my $ppi_user = DZT::PPIUser->new;

sub document_filename_is {
  my ($name, $content, $desc) = @_;

  my $file = Dist::Zilla::File::InMemory->new({
    name    => $name,
    content => $content,
  });

  my $document = $ppi_user->ppi_document_for_file($file);
  is($document->filename, $name, $desc);
}

document_filename_is(
  'lib/DZT/Sample.pm',
  "package DZT::Sample;\n1;\n",
  'document records the name of the file it came from',
);

document_filename_is(
  'lib/DZT/Other.pm',
  "package DZT::Sample;\n1;\n",
  'identical content in another file gets its own filename, not a cached one',
);

done_testing;
