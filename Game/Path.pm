package Game::Path;
use v5.38;
use feature qw(class);
no warnings 'experimental::class';

class Game::Path
{
    use lib '.';
    use Game::Point;
    use DDP;
    no warnings 'experimental::for_list';

    field $start :param;
    field $end :param;
    field $board :param;

    field @directions = (
        { x =>  0, y => -1 },
        { x =>  0, y =>  1 },
        { x => -1, y =>  0 },
        { x =>  1, y =>  0 },
        { x => -1, y => -1 },
        { x =>  1, y => -1 },
        { x => -1, y =>  1 },
        { x =>  1, y =>  1 });
    field @dr = map { $_->{y} } @directions;
    field @dc = map { $_->{x} } @directions;

    method find($start, $end)
    {
        my @queue = ($start);
        my %visited;
        my %parent;
        $visited{$start->{y}}{$start->{x}} = 1;

        while (@queue) {
            my $current = shift @queue;
            my ($row, $col) = ($current->{y}, $current->{x});

            last if $row == $end->{y} && $col == $end->{x};

            for my $d (0..7) {
                my $new_row = $row + $dr[$d];
                my $new_col = $col + $dc[$d];
                my $p = {x => $new_col, y => $new_row};
                if ($self->is_valid($p) && !$visited{$new_row}{$new_col}) {
                    push @queue, $p;
                    $visited{$new_row}{$new_col} = 1;
                    $parent{$new_row}{$new_col} = {x => $col, y => $row};
                }
            }
        }

        my @path;
        my ($row, $col) = ($end->{y}, $end->{x});
        while (defined $parent{$row}{$col}) {
            unshift @path, {x => $col, y => $row};
            ($row, $col) = $parent{$row}{$col}->@{qw(y x)};
        }

        return @path
    }

    method is_valid($point)
    {
        my ($row, $col) = @{$point}{qw(y x)};
        return $row >= 0 && $row < @{$board}
            && $col >= 0 && $col < @{$board->[0]}
            && !$board->[$row][$col];
    }
}

1;
