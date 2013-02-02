use strict;
use warnings;

package # do not index
  Dist::Zilla::Plugin::UploadToCPAN::_Uploader;

use CPAN::Uploader 0.101550; # ua string
our @ISA = 'CPAN::Uploader';

# Report CPAN::Uploader's version, not ours:
sub _ua_string { CPAN::Uploader->_ua_string }

sub log {
  my $self = shift;
  $self->{'Dist::Zilla'}{plugin}->log(@_);
}

1;
