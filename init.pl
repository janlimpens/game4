#! /usr/bin/env perl

use v5.38;
use lib '.';
use Carp::Always;
use Game;

my $ctx = Game->new();

$SIG{INT} = sub { $ctx->stop() };

my $book = $ctx->add_entity (
    name => 'a book',
    weight => 1,
    readable => 1,
    effects => { knowledge => 1 }, );

my $e1 = $ctx->add_entity (
    name => 'Alice',
    position => { x => 0, y => 0 },
    velocity => 1,
    weight => 3000,
    height => 1.2,
    collides => 1,
    inventory => { $book => 1 },
    interactive => {
        close => undef,
        drop => undef,
        dump => undef,
        eat => undef,
        go_to => undef,
        look_around => undef,
        move => undef, # from pos/vel?
        open => undef,
        quit => undef,
        take => undef,
    });

my $e2 = $ctx->add_entity (
    name => 'Bob',
    position => { x => 5, y => 5 },
    collides => 1,
    greeter => 1,
    npc => {
        walks_around => 3
    });

my $e3 = $ctx->add_entity (
    weather => 'nice',
    start => { x => 0, y => 0 },
    end => { x => 10, y => 10 } );

my $e4 = $ctx->add_entity (
    weather => 'terrible',
    start => { x => 3, y => 3 },
    end => { x => 6, y => 6 } );

# my %tree_positions;
# while (%tree_positions < 10)
# {
#     my $x = int rand 20;
#     my $y = int rand 20;
#     $tree_positions{"$x,$y"} = Game::Point->new($x, $y);
# }

# for (values %tree_positions) {
#     $ctx->add_entity (
#         name => 'a large tree',
#         actions => 'climb',
#         position => $_,
#     );
# }

for (0..5)
{
    next if $_ == 3;
    $ctx->add_entity (
        name => 'a stone wall',
        position => { x => $_, y => 2 },
        weight => 1000_000,
        collides => 1,);
}

$ctx->add_entity(
    name => 'a creaky old door',
    position => { x => 3, y => 2 },
    weight => 20,
    collides => 1,
    opens => 1,
    height => 0.6);

my $cookie = $ctx->add_entity (
    name => 'a cookie',
    position => { x => 3, y => 1 },
    effects => {
        growth => { ratio => 0.5, duration => 3 } },
    weight => 10,
    food => 1);

my $shroom = $ctx->add_entity (
    name => 'a funny mushroom',
    position => { x => 7, y => 8 },
    effects => {
        growth => { ratio => 2, duration => 3 },
        hallucination => { duration => 1 } },
    weight => 5,
    food => 1);

my $pizza = $ctx->add_entity(
    name => "Artur's pizza",
    position => { x => 7, y => 5 },
    weight => 400,
    food => 1);

$ctx->start();
