use strict;
use warnings;
package DZT::Sample;

sub return_arrayref_of_values_passed {
  my $invocant = shift;
  return \@_;
}

package DZT::Sample_2;

1;
