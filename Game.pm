package Game;
use lib '.';
use v5.38;
no warnings 'experimental::class';
use feature 'class';
use ECS::Tiny;
use Game::Point;

class Game:isa(ECS::Tiny::Context)
{
    no warnings qw(experimental);
    use DDP;
    use builtin qw(true false);
    use Carp qw(croak confess);
    use List::Util qw(all any);

    field %position_to_entities;
    field %entity_to_position;
    field %names;
    field $stop_it;
    field %last_action;
    field %movements = (
        n  => Game::Point->new(0, 1),
        ne => Game::Point->new(1, 1),
        e  => Game::Point->new(1, 0),
        se => Game::Point->new(1, -1),
        s  => Game::Point->new(0, -1),
        sw => Game::Point->new(-1, -1),
        w  => Game::Point->new(-1, 0),
        nw => Game::Point->new(-1, 1),
    );

    field %units = (
        weight => 'g',
        velocity => 'm/s',
        position => 'm',
        height => 'm',
        time => 's',
    );

    method start($times=undef)
    {
        $self->add_processor(\&get_names);
        $self->add_processor(\&get_positions);
        $self->add_processor(\&greet);
        $self->add_processor(\&interact_dispatcher);
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
        my @components = $self->get_components_by_name('name');
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

        my @components = $self->get_components_by_name('position');

        for my ($id, $position) (@components)
        {
            bless $position, 'Game::Point';
            push $position_to_entities{ $position->key() }->@*, $id;
            $entity_to_position{ $id } = bless $position, 'Game::Point';
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
        my $all_weather = [reverse $self->get_components_by_name('weather', 'start', 'end')];

        my @greeters = $self->get_components_by_name('greeter', 'name', 'position');

        for my ($id, $greeter, $name, $position) (@greeters)
        {
            my @adjacent = grep { $_ ne $id && $names{$_} } $self->get_adjacent_entities($position);
            next unless @adjacent;
            my $weather = $self->get_weather_at_position($position, $all_weather);
            for my $adjacent (@adjacent)
            {
                my $adj_name = $names{$adjacent};
                say STDERR $weather
                    ? "$name: Hello $adj_name! The weather is $weather, today."
                    : "$name: Hello $adj_name!";
            }
        }
        return
    }

    method interact_dispatcher ()
    {
        my @components = $self->get_components_by_name(qw(interactive name position));
        for my ($id, $interactive, $name, $position) (@components)
        {
            my $action;
            my @args;
            until ($action)
            {
                say sprintf "$name is at %s.", $position->stringify();
                say sprintf 'What should $name do? [%s]', join ', ', sort keys $interactive->%*;
                my $input = <STDIN>;
                chomp $input;
                my ($a, @a) = split ' ', ($input//'');
                $a //= '';
                if ($a eq '.' && exists $last_action{$id})
                {
                    ($action, @args) = $last_action{$id}[-1]->@*;
                    say sprintf 'Repeating last action: %s %s', $action, join ' ', @args;
                    # p $last_action{$id}, as => 'last_action';
                } elsif (exists $interactive->{$a}) {
                    ($action, @args) = ($a, @a);
                } else {
                    say "I can't do that!";
                }
            }
            push $last_action{$id}->@*, [$action, @args];
            say "Action: $action with args: @args";
            my %actions = (
                move => method { my ($dir) = @args; $self->move_interactively($id, $dir) },
                look_around => method { $self->look_around($id) },
                inspect => method { say "Inspect!" },
                eat => method { my ($food) = @args; $self->eat($id, $food) },
                give => method { say "Give!" },
                take => method { my ($item) = @args; $self->take($id, $item) },
                throw => method { say "Throw!" },
                accelerate => method { say "Accelerate!" },
                sleep => method { say "Sleep!" },
                quit => method { say "Goodbye!"; $stop_it = 1 },
                dump => method { $self->dump() },
            );
            # for my $action (keys %actions)
            # {
            #     $actions{substr($action, 0, 1)} = $actions{$action};
            # }
            $actions{$action}->($self, $id, @args);
        }
    }

    method take ($entity, $item)
    {
        my $give_up = 0;
        until ($item || $give_up) {
            say "What would you like to take?";
            my $i = <STDIN>;
            chomp $i;
            $give_up = 1 && next() if $i eq '';
            $item = $i
                if $self->entity_has_component($entity, 'takeable');
        }
        my ($c, $ci) = $self->get_components_for_entity($entity, $item);
        my $distance = $entity_to_position{$entity}->get_distance($entity_to_position{$item});
        if ($distance > 1)
        {
            say "You can't reach that from here!";
            return
        }
        my $name = $names{$entity} // 'Entity';
        if ($ci && $ci->{weight})
        {
            my $item_name = $names{$item} // 'item';
            $self->remove_component($item, 'position');
            $c->{inventory}{$item} = 1;
            $c->{weight} += $ci->{weight} if $c->{weight};
            say "$name takes $item_name";
        } else {
            say "$name can't take that!";
        }
        return
    }

    method eat ($entity, $item)
    {
        my ($c, $ci) = $self->get_components_for_entity($entity, $item);
        my $inventory = $c->{inventory} // {};
        my $name = $names{$entity} // 'Entity';
        my $food_name = $names{$item} // 'item';
        unless ($inventory->{$item})
        {
            say "$name doesn't have $food_name!";
            return
        }
        if ($ci && $ci->{food})
        {
            my $item_name = $names{$item} // 'item';
            say "$name eats $item_name";
            $c->{weight} -= $ci->{weight}
                if $c->{weight} && $ci->{weight};
            $self->remove_entity($item);
        } else {
            say "$name can't eat that!";
        }
        return
    }

    method move_interactively ($entity, $movement)
    {
        my ($c) = $self->get_components_for_entity($entity);
        my %c = $c ? $c->%* : ();
        my $velocity = $c{velocity} //= { x => 0, y => 0 };
        my $name = $names{$entity} // 'Entity';
        until ($movement && $movements{$movement})
        {
            say "Move $name ($entity) to where? [n, ne, e, se, s, sw, w, nw]";
            my $dir = <STDIN>;
            chomp $dir;
            $movement = $dir if $movements{$dir}
        }
        my $offset = $movements{$movement};
        # p $offset, as => 'offset';
        $c{position} = bless $c{position} => 'Game::Point';
        # p $c{position}, as => 'position';
        $c{position}->add($offset);
        # p $c{position}, as => 'new position';
        say "$name is now at [$c{position}{x}/$c{position}{y}]";
        return
    }

    method look_around ($entity, $distance=10)
    {
        my ($c) = $self->get_components_for_entity($entity);
        return unless $c->{position};
        my $position = bless $c->{position}, 'Game::Point';
        # p %names, as => 'names';
        my %adjacent =
            map {
                $names{$_}
                    ? ("$names{$_} ($_)" => (bless $entity_to_position{$_}, 'Game::Point'))
                    : ()
            }
            grep { $_ != $entity }
            $self->get_adjacent_entities($position, $distance);
        # %adjacent, as => 'adjacent named';
        my $name = $names{$entity};
        if (%adjacent)
        {
            say sprintf '%s sees: %s',
            $name,
            join ', ',
            map { "$_ at [$adjacent{$_}{x}/$adjacent{$_}{y}]" }
            keys %adjacent;
        } else {
            say "$name can see nothing of importance.";
        }

        return \%adjacent
    }
}

1;
