#! /usr/bin/env perl

use v5.38;
use Test2::V0;
use lib '.';
use Game;
use Game::Interactive;
use DDP;

my $ctx = Game->new();

my $e00 = $ctx->add_entity (
    name => 'e(0/0)',
    position => { x => 0, y => 0 } );

my $e01 = $ctx->add_entity (
    name => 'e(0/1)',
    position => { x => 0, y => 1 } );

my $e77 = $ctx->add_entity (
    name => 'e(7/7)',
    position => { x => 7, y => 7 } );

my $e2020 = $ctx->add_entity (
    name => 'e(20/20)',
    position => { x => 20, y => 20 } );

# $DB::single = 1;
$ctx->start(1);
# p $ctx->dump();
my @adjacent = $ctx->get_adjacent_entities({ x => 0, y => 1 }, 5);

is \@adjacent, [ $e00, $e01 ], 'adjacent entities';

my $interactive = Game::Interactive->new(ctx=>$ctx);
my $look_around = $interactive->look_around($e00, 9);
# p $look_around, as => 'look around';
is $look_around->{'e(0/1) (1)'}->key(), '0/1', 'Game::Point', 'look around';
is $look_around->{'e(7/7) (2)'}->key(), '7/7', 'Game::Point', 'look around';

# p $look_around;
done_testing();
