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

my $afflicted = $ctx->add_entity (
    effect => { growth => { ratio => 2, duration => 3 } }
);

# $DB::single = 1;
$ctx->start(1);
# p $ctx->dump();

my $interactive = Game::Interactive->new( ctx => $ctx );
# $DB::single = 1;
my $look_around = $interactive->look_around($e00, 10);
# p $look_around, as => 'look around';

if (ok $look_around->{'e(0/1) (#1)'}, 'point 0/1 exists')
{
    is $look_around->{'e(0/1) (#1)'}->key(), '0/1', 'Game::Point', 'look around';
}

if (ok $look_around->{'e(7/7) (#2)'}, 'point 7/7 exists')
{
    is $look_around->{'e(7/7) (#2)'}->key(), '7/7', 'Game::Point', 'look around';
}

my @afflicted = $ctx->get_components_by_name('effects');
# p @afflicted;


# p $look_around;
done_testing();
