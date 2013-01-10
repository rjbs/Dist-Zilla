package DZT::Sample;
use strict;
use warnings;

sub return_arrayref_of_values_passed {
  my $invocant = shift;
  return \@_;
}

1;
