package Game::Path;
use v5.38;
use feature qw(class);
no warnings 'experimental::class';

class Game::Path
{
    # use Game::Point;
    use DDP;
    no warnings 'experimental::for_list';

    field $start :param;
    field $end :param;
    # an array of {x,y} or Points
    field $obstacles :param;
    field $search_limit :param = 5; # Configurable limit for search area growth

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
        my $area_size = 1;
        my %visited;
        my %parent;

        # Loop to increase search area size
        while ($area_size <= $search_limit) {
            my @queue = ($start);
            %visited = ();
            %parent = ();
            $visited{$start->{y}}{$start->{x}} = 1;

            while (@queue) {
                my $current = shift @queue;
                my ($row, $col) = ($current->{y}, $current->{x});

                last if $row == $end->{y} && $col == $end->{x};

                for my $d (0..7) {
                    my $new_row = $row + $dr[$d];
                    my $new_col = $col + $dc[$d];
                    my $p = {x => $new_col, y => $new_row};

                    if ($self->is_valid($p, $start, $end) && !$visited{$new_row}{$new_col}) {
                        push @queue, $p;
                        $visited{$new_row}{$new_col} = 1;
                        $parent{$new_row}{$new_col} = {x => $col, y => $row};
                    }
                }
            }

            # If path found, return it
            if (defined $parent{$end->{y}}{$end->{x}}) {
                my @path;
                my ($row, $col) = ($end->{y}, $end->{x});
                while (defined $parent{$row}{$col}) {
                    unshift @path, {x => $col, y => $row};
                    ($row, $col) = $parent{$row}{$col}->@{qw(y x)};
                }
                return @path;
            }

            # Increase search area size
            $area_size *= 1.5;
        }

        return (); # No path found within the search limit
    }

    method is_valid($point, $start, $end)
    {
        my ($row, $col) = $point->@{qw(y x)};
        return $row >= $start->{y} && $row <= $end->{y}
            && $col >= $start->{x} && $col <= $end->{x}
            && !$self->is_obstacle($point);
    }

    method is_obstacle($point)
    {
        my ($row, $col) = $point->@{qw(y x)};
        for my $obs (($obstacles//[])->@*) {
            return 1
                if $obs->{y} == $row && $obs->{x} == $col;
        }
        return
    }
}

1;
