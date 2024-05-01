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

    # an arrayref of (id, position, height) tuples
    # take care to filter away the viewing entity, as it's own height can hide
    # smaller things behind it
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
            push $by_angle{$angle}->@*, {
                id => $id,
                pos => $pos,
                height => $h,
                distance => $distance };
        }
        my @result;
        for my $homogon (values %by_angle )
        {
            my @homogon = sort { $a->{distance} <=> $b->{distance} } $homogon->@*;
            my $height = 0;
            for my $ent ($homogon->@*)
            {
                next if $height && $ent->{height} <= $height;
                $height = $ent->{height};
                push @result, $ent->{id};
            }
        }
        @result = sort @result;
        return @result
    }
}

1;
