package Game;
use lib '.';
use v5.38;
no warnings 'experimental::class';
use feature 'class';
use ECS::Tiny;
use Game::Point;
use Game::Interactive;
use Game::Path;

class Game:isa(ECS::Tiny::Context)
{
    no warnings qw(experimental);
    use DDP;
    use builtin qw(true false);
    use Carp qw(croak confess);
    use List::Util qw(all any first);

    field %position_to_entities;
    field %entity_to_position;
    field %entity_movements;
    field %names;
    field $stop_it;
    field %greeted;
    field %obstacles;
    field $units = {
        weight => 'g',
        velocity => 'm/s',
        position => 'm',
        height => 'm',
        time => 's',
    };

    method units() { return $units }

    method dump(@what)
    {
        $self->SUPER::dump(@what);
        if (grep { $_ eq 'names' } @what)
        {
            p %names, as => 'names';
        }
        if (grep { $_ eq 'positions' } @what)
        {
            p %position_to_entities, as => 'positions';
        }
        if (grep { $_ eq 'obstacles' } @what)
        {
            p %obstacles, as => 'obstacles';
        }
        if ( grep { $_ eq 'map' } @what )
        {
            $self->draw_map();
        }
        return
    }

    field $movements = {
        n  => Game::Point->new(0, 1),
        ne => Game::Point->new(1, 1),
        e  => Game::Point->new(1, 0),
        se => Game::Point->new(1, -1),
        s  => Game::Point->new(0, -1),
        sw => Game::Point->new(-1, -1),
        w  => Game::Point->new(-1, 0),
        nw => Game::Point->new(-1, 1)
    };

    method movements() { return $movements }

    method position_to_entities(){ return \%position_to_entities }

    method entities_at_position($pos)
    {
        my $ents = $position_to_entities{ref $pos ? $pos->key() : $pos};
        return $ents//[]
    }

    method entity_to_position(){ return \%entity_to_position }

    method names() { return \%names }

    method get_name($entity)
    {
        return unless $self->entity_exists($entity);
        return $self->get_name_or_undef($entity) // "Entity (#$entity)"
    }

    method get_name_or_undef($entity)
    {
        return unless $self->entity_exists($entity);
        return "$names{$entity} (#$entity)"
            if $names{$entity};
        return
    }

    method start($times=undef)
    {
        $self->add_processor(\&get_names);
        $self->add_processor(\&get_positions);
        $self->add_processor(\&get_obstacles);
        $self->add_processor(\&greet);
        my $interactive = Game::Interactive->new(ctx => $self);
        $self->add_processor(sub {$interactive->dispatch()});
        $self->add_processor(\&suffer);
        my $count = 0;
        until ($stop_it)
        {
            $self->update()
                unless $stop_it;
            $stop_it = 1 if $times && ++$count >= $times;
        }
    }

    method stop()
    {
        $stop_it = true;
    }

    # on_name_changed event
    method get_names ()
    {
        %names = ();
        my @components = $self->get_components_tuple_by_name('name');
        for my ($id, $name) (@components)
        {
            $names{$id} = $name;
        }
        return
    }

    # on_position_changed event
    method get_positions()
    {
        %position_to_entities = ();
        %entity_to_position = ();

        my @components = $self->get_components_tuple_by_name('position');

        for my ($id, $position) (@components)
        {
            # p $position, as => 'position';
            bless $position, 'Game::Point';
            push $position_to_entities{ $position->key() }->@*, $id;
            $entity_to_position{ $id } = $position;
            push $entity_movements{ $id }->@*, $position;
        }

        return
    }

    method get_obstacles()
    {
        %obstacles = ();
        for my ($id, $collides, $position) ($self->get_components_tuple_by_name('collides', 'position'))
        {
            next unless $collides;
            $position = bless $position, 'Game::Point';
            bless $position, 'Game::Point';
            $obstacles{$position->key()} = undef;
        }
        for my ($id, $height, $position) ($self->get_components_tuple_by_name('height', 'position'))
        {
            next unless $height;
            $position = bless $position, 'Game::Point';
            next unless $obstacles{$position->key()};
            bless $position, 'Game::Point';
            $obstacles{$position->key()} = $height;
        }
        return
    }

    # we call this at the end of the round and actually set the position.
    # Now we can check, whether the attempted move is valid.
    # method set_positions()
    # {
    #     for my ($id, $position) ($self->get_components_tuple_by_name('position'))
    #     {
    #         next if $entity_to_position{$id}->equals($position);
    #         if ()
    #         $entity_to_position{$id} = $position;
    #         push $position_to_entities{$position->key()}->@*, $id;
    #     }
    # }

    method has_collission($position)
    {
        my $ents = $self->position_to_entities()->{$position->key()};
        return false unless $ents;
        return first { $self->get_components_for_entity($_)->{collides} } $ents->@*
    }

    method is_within_distance($entity, $other, $distance)
    {
        my $pos = $self->entity_to_position()->{$entity};
        my $other_pos = $self->entity_to_position()->{$other};
        return $pos->get_distance($other_pos) <= $distance
    }

=head3

move_entity moves an entity in a given direction [n nw w ...].
It checks for collissions and will stop if something is in the way.
It also checks for height restrictions and will stop if the entity is too low to
fit through.
=cut

    method move_entity ($entity, $current_pos, $velocity, $movement=undef)
    {
        my $offset = $movements->{$movement}->multiply(Game::Point->new($velocity, $velocity));
        my $target = $current_pos->copy()->add($offset);
        my @points_between = $current_pos->get_points_between($target);
        for my $point (@points_between, $target)
        {
            if (my $with = $self->has_collission($point))
            {
                my $name = $names{$entity} // "Entity ($entity)";
                my $other = $names{$with} // "Entity ($with)";
                say "$name bumps into $other!";
                last
            }
            my $c = $self->get_components_for_entity($entity);
            if (my $height = $c->{height})
            {
                my ($min_height) =
                    sort
                    map { $_->{height} // () }
                    grep { $_->{opens} }
                    map { $self->get_components_for_entity($_) // ()}
                    grep { $_ != $entity }
                    $self->entities_at_position($point)->@*;
                $min_height //= $height;
                if ($min_height < $height)
                {
                    my $name = $names{$entity} // "Entity ($entity)";
                    say "$name doesn't fit through ($min_height m)!";
                    last
                }
            }
            $current_pos->{x} = $point->{x};
            $current_pos->{y} = $point->{y};
        }
        return
    }

    method get_weather_at_position($pos, $all_weather, $default='ok')
    {
        for my ($end, $start, $weather, $id) ($all_weather->@*)
        {
            $end = bless $end, 'Game::Point';
            $start = bless $start, 'Game::Point';
            return $weather
                if $pos->is_within_area($start, $end);
        }
        return $default
    }

    method get_adjacent_entities($pos, $distance=1)
    {
        # p $pos, as => 'pos';
        return unless $pos;
        $pos = bless $pos, 'Game::Point';

        return ($position_to_entities{$pos->key()}//[])->@*
            if $distance < 1;

        my @entities =
            map { $position_to_entities{$_->key()}->@* }
            grep {
                $position_to_entities{$_->key()}
                && $pos->is_within_distance($_, $distance)
            }
            map {
                my $x = $_;
                map { Game::Point->new($x, $_)->add($pos) }
                -$distance .. $distance;
            }
            -$distance .. $distance;
        # p @entities, as => 'entities';

        return @entities
    }

    method greet ()
    {
        my $all_weather = [reverse $self->get_components_tuple_by_name('weather', 'start', 'end')];

        my @greeters = $self->get_components_tuple_by_name('greeter', 'name', 'position');

        for my ($id, $greeter, $name, $position) (@greeters)
        {
            my @adjacent = grep { $_ ne $id && $names{$_} } $self->get_adjacent_entities($position);
            next unless @adjacent;
            my $weather = $self->get_weather_at_position($position, $all_weather);
            for my $adjacent (grep { !$greeted{$id}{$_} } @adjacent)
            {
                my $adj_name = $names{$adjacent};
                say STDERR $weather
                    ? "$name: Hello $adj_name! The weather is $weather, today."
                    : "$name: Hello $adj_name!";
                $greeted{$id}{$adjacent} = 1;
            }
        }
        return
    }

    method suffer ()
    {
        my $effect_dispatch = {
            growth => method($id, $params)
            {
                my $ratio = $params->{ratio};
                my $duration = $params->{duration};
                my ($c) = $self->get_components_for_entity($id);
                return unless $c->{height};
                $c->{height} *= $ratio;
                my $name = $self->names()->{$id} // 'Entity';
                my $verb = $ratio > 1 ? 'grows' : 'shrinks';
                say "$name $verb to $c->{height}m";
                $params->{duration}--;
                return
            },
            hallucination => method($id, $params) {
                say 'Everything seems a little bit different.';
            }
        };

        for my($id, $effects) ($self->get_components_tuple_by_name('suffers'))
        {
            # p $effects;
            for my $e (keys $effects->%*)
            {
                if (my $func = $effect_dispatch->{$e})
                {
                    $func->($self, $id, $effects->{$e})
                }
                if (($effects->{$e}{duration}//0) <= 0)
                {
                    delete $effects->{$e};
                }
            }
            $self->remove_component($id, 'suffers')
                unless $effects->%*;
        }
    }

    method go_to ($entity, $target)
    {
        state %targets;
        my $c = $self->get_components_for_entity($entity);
        $targets{$entity} = $target;
        my $pos = $self->entity_to_position()->{$entity};
        my $target_pos = $self->entity_to_position()->{$target};
        unless ($target_pos)
        {
            delete $targets{$entity};
            say "No such target!";
            return
        }
        if ($pos->equals($target_pos))
        {
            delete $targets{$entity};
            my $name = $self->get_name($entity);;
            say sprintf "$name has arrived at %s!", $target_pos->stringify();
            return
        }
        my $height = $c->{height};
        my $path = Game::Path->new (
            start => $pos,
            end => $target_pos,
            obstacles => [ map { Game::Point->from($_) } keys %obstacles ]);
        my @path = $path->find($pos, $target_pos);
        p @path;
        my $velocity = $c->{velocity} // 1;
        my $next_pos = bless(($path[$velocity]//$path[-1]), 'Game::Point');
        if ($next_pos)
        {
            $pos->{x} = $next_pos->{x};
            $pos->{y} = $next_pos->{y};
            say sprintf "Moving to %s", $next_pos->stringify();
        }
        return
    }

    method find_min_max_points (@points)
    {
        my $min_x = $points[0]->{x};
        my $min_y = $points[0]->{y};
        my $max_x = $points[0]->{x};
        my $max_y = $points[0]->{y};

        for my $point (@points) {
            $min_x = $point->{x} if $point->{x} < $min_x;
            $min_y = $point->{y} if $point->{y} < $min_y;
            $max_x = $point->{x} if $point->{x} > $max_x;
            $max_y = $point->{y} if $point->{y} > $max_y;
        }

        my $min_point = bless { x => $min_x, y => $min_y }, 'Game::Point';
        my $max_point = bless { x => $max_x, y => $max_y }, 'Game::Point';

        return ($min_point, $max_point)
    }

    method draw_map()
    {
        my @points = sort { $a->{x} + $a->{y} <=> $b->{x} + $b->{y} }
            map { Game::Point->from($_) }
            keys %position_to_entities;
        # p @points, as => 'points';
        my ($min, $max) = $self->find_min_max_points(@points);

        # p $min, as => 'min';
        # p $max, as => 'max';
        print "   ";
        print "$_ "
            for ($min->{x} .. $max->{x});
        print "\n";
        for my $y (reverse $min->{y} .. $max->{y})
        {
            print "$y: ";
            for my $x ($min->{x} .. $max->{x})
            {
                my $pos = Game::Point->new($x, $y);
                my ($ent) = $self->entities_at_position($pos)->@*;
                if ($ent && (my $name = $self->get_name_or_undef($ent)))
                {
                    $name = $name =~ s/^((?:a.?|the)\s?)//r;
                    print substr($name, 0, 1);
                } else {
                    print '.';
                }
                print ' ';
            }
            print "\n";
        }
    }
}

1;
