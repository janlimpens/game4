#! /usr/bin/env perl

use v5.38;
use lib '.';
use Game;

my $ctx = Game->new();

$SIG{INT} = sub { $ctx->stop() };

my $e1 = $ctx->add_entity (
    name => 'Alice',
    position => { x => 0, y => 0 },
    velocity => 1,
    interactive => {
        eat => undef,
        inspect => undef,
        look_around => undef,
        move => undef, # from pos/vel?
        take => [],
        drop => undef,
        quit => undef,
    }
    );

my $e2 = $ctx->add_entity (
    name => 'Bob',
    position => { x => 5, y => 5 },
    greeter => 1,
    npc => {
        walks_around => 3
    });

my $e3 = $ctx->add_entity (
    weather => 'nice',
    start => { x => 0, y => 0 },
    end => { x => 10, y => 10 });

my $e4 = $ctx->add_entity (
    weather => 'terrible',
    start => { x => 3, y => 3 },
    end => { x => 6, y => 6 }
);

my $tree = $ctx->add_entity (
    name => 'a large tree',
    position => { x => 2, y => 2 },
);

my $cookie = $ctx->add_entity (
    name => 'a cookie',
    position => { x => 3, y => 3 },
    causes => { growth => 0.5 },
    weight => 10,
    food => 1,
);

my $shroom = $ctx->add_entity (
    name => 'a funny mushroom',
    position => { x => 7, y => 8 },
    causes => { growth => 1.5, hallucination => 1 },
    weight => 5,
    food => 1,
);

$ctx->start();
