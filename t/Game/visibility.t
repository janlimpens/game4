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
    my %entities = (
        1 => { position => Point->new(0, 2), height => 1 }, #v
        2 => { position => Point->new(0, 3), height => 1 },
        3 => { position => Point->new(0, 4), height => 1.5 }, #v
        4 => { position => Point->new(0, 5), height => 1.5 },
        5 => { position => Point->new(0, 6), height => 2 }, #v
        6 => { position => Point->new(0, 11), height => 10 },
    );

    my $visibility = Game::Visibility->new(
        entities => \%entities,
    );

    my $pov = Game::Point->new(0, 0);

    my @visible = $visibility->visible_entities($pov, 6);
# p @visible;
    is scalar(@visible), 3, '3 entities visible';
    is $visible[0], 1, 'Entity 1 visible';
    is $visible[1], 3, 'Entity 3 visible';
    is $visible[2], 5, 'Entity 5 visible';
};

subtest diagonal => sub
{
    my %entities = (
        1 => { position => Point->new(1, 1), height => 1 }, #v
        2 => { position => Point->new(2, 2), height => 1 },
        3 => { position => Point->new(3, 3), height => 1.5 }, #v
        4 => { position => Point->new(4, 4), height => 1.5 },
        5 => { position => Point->new(5, 5), height => 2 }, #v
        6 => { position => Point->new(11, 11), height => 10 },
    );

    my $visibility = Game::Visibility->new(
        entities => \%entities,
    );

    my $pov = Game::Point->new(0, 0);

    my @visible = $visibility->visible_entities($pov, 8);

    is scalar(@visible), 3, '3 entities visible';
    is $visible[0], 1, 'Entity 1 visible';
    is $visible[1], 3, 'Entity 3 visible';
    is $visible[2], 5, 'Entity 5 visible';
};

subtest diverse_points => sub {
    my %entities = (
        1 => { position => Game::Point->new(1, 1),  height => 1 },
        2 => { position => Game::Point->new(2, 2),  height => 1.1 },
        3 => { position => Game::Point->new(1, 3),  height => 1.2 },
        4 => { position => Game::Point->new(6, 2),  height => 1.3 },
        5 => { position => Game::Point->new(-1, 2), height => 1.4 },
        6 => { position => Game::Point->new(-2, 4), height => 1.5 },
        7 => { position => Game::Point->new(-4, 2), height => 1.6 },
        8 => { position => Game::Point->new(-6, 4), height => 1.7 },
    );
    my $r =6.4;
    my $pov = Game::Point->new(0, 0);
    my $visibility = Game::Visibility->new(
        entities => \%entities,
    );
    my @visible = $visibility->visible_entities($pov, $r);
    is scalar(@visible), 7, '7 entities visible';
};

done_testing();

1;
