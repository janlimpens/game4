#! /usr/bin/env perl

use v5.38;
use lib '.';
use DDP;
use Game::Point;
use Test2::V0;

my $p44 = Game::Point->new(4,4);
is $p44->key(), '4/4';

my $h = { x => 1, y => 2 };
my $p12 = bless $h, 'Game::Point';
is $p12->key(), '1/2';

my $string = '3/4';
my $p34 = Game::Point->from($string);
is $p34->key(), '3/4';

my $arr = [ 3, 4 ];
my $p34_2 = Game::Point->from($arr);
is $p34_2->key(), '3/4';

ok $p34->equals($p34_2);

my $result = $p12->add($p34);
is $result->key(), '4/6';

my $distance = $p12->get_distance($p34);
is $distance, 2.23606797749979;

done_testing();
