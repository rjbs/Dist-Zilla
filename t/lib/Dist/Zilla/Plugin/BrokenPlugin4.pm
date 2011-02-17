use strict;

use warnings;

package Dist::Zilla::Plugin::BrokenPlugin;

use Moose;
with "Some::Package::That::Does::Not::Exist::Due::To::A::Typo";

0;

