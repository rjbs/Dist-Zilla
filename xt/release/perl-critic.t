#!perl
use strict;
use warnings;
use Test::More;

if (eval { require Test::Perl::Critic }) {
  Test::Perl::Critic::all_critic_ok();
} else {
  plan skip_all => "couldn't load Test::Perl::Critic";
}
