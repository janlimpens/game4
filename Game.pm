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

    method start()
    {
        $self->add_processor(\&get_names);
        $self->add_processor(\&interact_dispatcher);
        $self->add_processor(\&get_positions);
        $self->add_processor(\&greet);

        until ($stop_it)
        {
            $self->update()
                unless $stop_it;
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
        for my ($id, $name, $position) (@components)
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
        return unless $pos;
        $pos = bless $pos, 'Game::Point';
        my %adjacent;
        for my $x ($pos->{x} - $distance .. $pos->{x} + $distance)
        {
            for my $y ($pos->{y} - $distance .. $pos->{y} + $distance)
            {
                my $p = Game::Point->new($x, $y);
                next unless $pos->is_within_distance($p, $distance);
                if (my $entities = $position_to_entities{$p->key()})
                {
                    $adjacent{$_} = 1
                        for $entities->@*
                }
            }
        }
        return keys %adjacent
    }

    method greet ()
    {
        my $all_weather = [reverse $self->get_components_by_name('weather', 'start', 'end')];

        my @greeters = $self->get_components_by_name('greeter', 'name', 'position');

        for my ($id, $greeter, $name, $position) (@greeters)
        {
            my @adjacent = grep { $names{$_} } $self->get_adjacent_entities($position);
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
        my @components = $self->get_components_by_name(qw(interactive));
        for my ($id, $interactive) (@components)
        {
            my $action;
            my @args;
            until ($action)
            {
                say sprintf 'What should I do? [%s]', join ', ', sort keys $interactive->%*;
                my $a = <STDIN>;
                chomp $a;
                $a //= '';
                ($a, @args) = split ' ', ($a);
                if ($a eq '.' && exists $last_action{$id})
                {
                    $a = $last_action{$id};
                } elsif (exists $interactive->{$a} || exists $interactive->{substr $a ,1, 0} ) {
                    $last_action{$id} = $action = $a;
                } else {
                    say "I can't do that!";
                }
            }
            my %actions = (
                move => method { my ($dir) = @args; $self->move_interactively($id, $dir) },
                look_around => method { $self->look_around($id) },
                inspect => method { say "Inspect!" },
                eat => method { my ($food) = @args; $self->eat($id, $food) },
                give => method { say "Give!" },
                take => method { say "Take!" },
                throw => method { say "Throw!" },
                accelerate => method { say "Accelerate!" },
                sleep => method { say "Sleep!" },
                quit => method { say "Goodbye!"; $stop_it = 1 },
            );
            for my $action (keys %actions)
            {
                $actions{substr($action, 0, 1)} = $actions{$action};
            }
            $actions{$action}->($self, $id, @args);
        }
    }

    method eat ($entity, $item)
    {
        my $give_up = 0;
        until ($item || $give_up) {
            say "What would you like to eat?";
            my $i = <STDIN>;
            chomp $i;
            $give_up = 1 && next() if $i eq '';
            $item = $i
                if $self->entity_has_component($entity, 'food');
        }
        my ($c, $ci) = $self->get_components_for_entity($entity, $item);
        my $name = $names{$entity} // 'Entity';
        if ($ci && $c->{food})
        {
            my $item_name = $names{$item} // 'item';
            say "$name eats $item_name";
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
        p $offset, as => 'offset';
        $c{position} = bless $c{position} => 'Game::Point';
        p $c{position}, as => 'position';
        $c{position}->add($offset);
        p $c{position}, as => 'new position';
        say "$name is now at [$c{position}{x}/$c{position}{y}]";
        return
    }

    method look_around ($entity, @args)
    {
        my $distance = 10;
        my ($c) = $self->get_components_for_entity($entity);
        my %c = $c ? $c->%* : ();
        my %adjacent =
            map {
                $names{$_}
                    ? ($names{$_} => (bless $entity_to_position{$_}, 'Game::Point'))
                    : ()
            }
            $self->get_adjacent_entities($c{position}, $distance);
        # p %adjacent, as => 'adjacent named';
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
    }
}

1;
