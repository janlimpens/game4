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

subtest 'get_points_between' => sub
{
    my $point1 = Game::Point->new(1, 1);
    my $point2 = Game::Point->new(3, 3);

    my @points_between = $point1->get_points_between($point2);

    is([map { $_->stringify() } @points_between], [
        Game::Point->new(2, 2)->stringify()
    ], 'Points between ok');

    my $point3 = Game::Point->new(7, 19);

    my $further_away = my @p = $point1->get_points_between($point3);
    # p @p;
    is scalar $further_away, 17, 'Further away points ok';
    # for my $p (reverse ($point1, @p, $point3)) {
    #     print STDERR "\n";
    #     for ($point1->{y}..$point3->{y}) {
    #         print STDERR $p->{y} == $_ ? 'X' : '.';
    #     }
    # }
};

subtest parses_negative_value => sub
{
    my $point = Game::Point->from('-1/-2');
    is $point->key(), '-1/-2';
};

done_testing();
