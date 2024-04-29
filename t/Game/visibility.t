#! /usr/bin/env perl

use v5.38;
use lib '.';
use DDP;
use Game::Point;
use Game::Visibility;
use Test2::V0;
use constant Point => 'Game::Point';

subtest straight_line => sub
{
    my @entities = (
        1, Point->new(0, 2), 1, #v
        2, Point->new(0, 3), 1,
        3, Point->new(0, 4), 1.5, #v
        4, Point->new(0, 5), 1.5,
        5, Point->new(0, 6), 2, #v
        6, Point->new(0, 11), 10,
    );

    my $visibility = Game::Visibility->new(
        entities => \@entities,
    );

    my $pov = Game::Point->new(0, 0);

    my @visible = $visibility->visible_entities($pov, 6);

    is scalar(@visible), 3, '3 entities visible';
    is $visible[0], 1, 'Entity 1 visible';
    is $visible[1], 3, 'Entity 3 visible';
    is $visible[2], 5, 'Entity 5 visible';
};

subtest diagonal => sub
{
    my @entities = (
        1, Point->new(1, 1), 1, #v
        2, Point->new(2, 2), 1,
        3, Point->new(3, 3), 1.5, #v
        4, Point->new(4, 4), 1.5,
        5, Point->new(5, 5), 2, #v
        6, Point->new(11, 11), 10,
    );

    my $visibility = Game::Visibility->new(
        entities => \@entities,
    );

    my $pov = Game::Point->new(0, 0);

    my @visible = $visibility->visible_entities($pov, 8);

    is scalar(@visible), 3, '3 entities visible';
    is $visible[0], 1, 'Entity 1 visible';
    is $visible[1], 3, 'Entity 3 visible';
    is $visible[2], 5, 'Entity 5 visible';
};

subtest diverse_points => sub {
    my @entities = (
        1, Game::Point->new(1, 1), 1,
        2, Game::Point->new(2, 2), 1.1,
        3, Game::Point->new(1, 3), 1.2,
        4, Game::Point->new(6, 2), 1.3,
        5, Game::Point->new(-1, 2), 1.4,
        6, Game::Point->new(-2, 4), 1.5,
        7, Game::Point->new(-4, 2), 1.6,
        8, Game::Point->new(-6, 4), 1.7,
    );
    my $r =6.4;
    my $pov = Game::Point->new(0, 0);
    my $visibility = Game::Visibility->new(
        entities => \@entities,
    );
    my @visible = $visibility->visible_entities($pov, $r);
    is scalar(@visible), 7, '7 entities visible';
};

done_testing();

1;
