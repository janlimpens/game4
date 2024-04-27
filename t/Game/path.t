#! /usr/bin/env perl

use v5.38;
use lib '.';
use DDP;
use Game::Point;
use Game::Path;
use Test2::V0;

sub draw_way_through($board, $path)
{
    my $board_copy = [ map { [ $_->@* ] } $board->@* ];
    for my $point ($path->@*) {
        $board_copy->[$point->{y}][$point->{x}] = '@';
    }
    for my $row ($board_copy->@*) {
        say STDERR join '', map { $_ ? " $_ " : ' . ' } $row->@*;
    }
}

my $empty_board = [
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0]];

my $with_obstacles = [
    reverse
    [0, 0, 0, 0],
    [0, 1, 0, 0],
    [0, 1, 1, 0],
    [0, 0, 0, 0]];

my $labyrinth = [
    [qw(0 1 1 1 1 1 1 1 1 1)],
    [qw(0 0 0 0 0 0 0 0 0 1)],
    [qw(1 1 1 1 1 1 1 1 0 1)],
    [qw(1 0 0 0 0 0 0 1 0 1)],
    [qw(1 0 1 1 1 1 0 1 0 1)],
    [qw(1 0 1 0 0 0 0 1 0 1)],
    [qw(1 0 1 0 1 0 1 1 0 1)],
    [qw(1 0 1 1 1 0 0 0 0 1)],
    [qw(1 0 0 0 1 1 1 1 1 1)],
    [qw(1 1 1 1 0 0 0 0 0 0)]];

sub get_obstacles($board)
{
    my @obstacles;
    for my $y (0..$board->$#*) {
        for my $x (0..$board->[$y]->$#*) {
            push @obstacles, { x => $x, y => $y } if $board->[$y][$x];
        }
    }
    return @obstacles;
}

subtest simple_horizontal => sub
{
    my $start = Game::Point->new(0, 0);
    my $end = Game::Point->new(3, 0);
    my $path = Game::Path->new(
        start => $start,
        end => $end,
        obstacles => get_obstacles($empty_board));
    my @points = map { Game::Point->from($_) } $path->find($start, $end);
    is scalar @points, 3, '3 points';
    is $points[0]->key(), '1/0', '1/0';
    is $points[1]->key(), '2/0', '2/0';
    is $points[2]->key(), '3/0', 'end';
};

subtest simple_vertical => sub
{
    my $start = Game::Point->new(0, 0);
    my $end = Game::Point->new(0, 3);
    my $path = Game::Path->new(
        start => $start,
        end => $end,
        obstacles => get_obstacles($empty_board));
    my @points = map { Game::Point->from($_) } $path->find($start, $end);
    is scalar @points, 3, '3 points';
    is $points[0]->key(), '0/1', '0/1';
    is $points[1]->key(), '0/2', '0/2';
    is $points[2]->key(), '0/3', 'end';
};

subtest simple_diagonal => sub
{
    my $start = Game::Point->new(0, 0);
    my $end = Game::Point->new(3, 3);
    my $path = Game::Path->new(start => $start, end => $end, obstacles =>  $empty_board);
    my @points = map { Game::Point->from($_) } $path->find($start, $end);
    is scalar @points, 3, '3 points';
    is $points[0]->key(), '1/1', '1/1';
    is $points[1]->key(), '2/2', '2/2';
    is $points[2]->key(), '3/3', 'end';
};

subtest with_obstacles => sub
{
    my $start = Game::Point->new(0, 0);
    my $end = Game::Point->new(3, 3);
    my $path = Game::Path->new(start => $start, end => $end, obstacles =>  $with_obstacles);
    my @points = map { Game::Point->from($_) } $path->find($start, $end);
    is scalar @points, 5, 'path found';
    my @obstacles = grep { $with_obstacles->[$_->{y}][$_->{x}] } @points;
    ok !@obstacles, 'no obstacles';
};

subtest labyrinth => sub
{
    my $start = Game::Point->new(0, 0);
    my $end = Game::Point->new(9, 9);
    my $path = Game::Path->new(start => $start, end => $end, obstacles =>  $labyrinth);
    my @points = map { Game::Point->from($_) } $path->find($start, $end);
    draw_way_through($labyrinth, \@points);
    is scalar @points, 33, 'path found';
    my @obstacles = grep { $labyrinth->[$_->{y}][$_->{x}] } @points;
    ok !@obstacles, 'no obstacles';
};

done_testing();

1;
