#! /usr/bin/env perl

use v5.38;
use Test2::V0;
use lib '.';
use Game;
use DDP;

subtest get_distance => sub
{
    my $ctx = Game->new();
    my $d1 = $ctx->get_distance(
        {x => 1, y => 1},
        {x => 1, y => 10}
    );
    is $d1, 9, 'got vertical distance';

    my $dh = $ctx->get_distance(
        { x => 10, y => 1},
        { x => 20 => y => 1}
    );
    is $dh, 10, 'got horizontal dist';

    my $dd = $ctx->get_distance(
        { x => 0, y => 0 },
        { x => 1, y => 1 }
    );

};

subtest is_within_range => sub
{
    my $ctx = Game->new();

    my $e11 = { x => 1, y => 1 };
    my $e12 = { x => 1, y => 2 };
    my $e22 = { x => 2, y => 2 };
    my $e44 = { x => 4, y => 4 };

    ok( $ctx->is_within_range(1, $e11, $e22), 'e11 and e22 are adjacent' );
    ok( $ctx->is_within_range(1, $e11, $e12), 'e11 and e12 are adjacent' );
    ok( !$ctx->is_within_range(1, $e11, $e44), "e11 and e44 are't adjacent" );
    ok( $ctx->is_within_range(3, $e11, $e44), 'but e11 and e44 are 3 apart' );
};

done_testing();
