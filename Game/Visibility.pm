package Game::Visibility;
use v5.38;
use feature qw(class);
no warnings 'experimental::class';

class Game::Visibility
{
    use Math::Trig qw(pi);
    use DDP;
    use Game::Util;
    use Game::Point;

    no warnings 'experimental::for_list';

    field $entities :param;

    method visible_entities($pov, $radius)
    {
        bless $pov, 'Game::Point';
        my @entities_in_range;
        my %by_angle;
        for my ($id, $pos, $h) ($entities->@*)
        {
            my $distance = $pos->get_distance($pov);
            next if $distance > $radius;
            my $angle = atan2($pos->{y} - $pov->{y}, $pos->{x} - $pov->{x});
            # this might be too exact as a key
            push $by_angle{$angle}->@*, [ $id, $pos, $h, $distance ];
        }
        my @result;
        for my $iphd_arr (values %by_angle){
            my @arr = sort {$a->[3] <=> $b->[3]} $iphd_arr->@*;
            my $h = 0;
            for my $arr (@arr)
            {
                next if $arr->[2] <= $h;
                $h = $arr->[2];
                push @result, $arr->[0];
            }
        }
        return @result
    }
}

1;
