use strict;
use warnings;
package Dist::Zilla::Config;
use base 'Config::INI::MVP::Reader';

# This should steal liberally from App::Addex::Config, namely the "some
# multipart values" stuff and the ability to load and instantiate plugins based
# on the section names.
#
# I will almost certainly want the ability to have multiple instances of one
# class plugin, though, so there will need to be some kind of indirection,
# like:
#
# plugin = fooo
# plugin = feee
# [fooo]
# class = Meta::Maga::Foo
# ...
# [feee]
# class = Meta::Maga::Foo
# ...

1;
