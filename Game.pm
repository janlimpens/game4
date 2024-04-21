package Game;
use lib '.';
use v5.38;
no warnings 'experimental::class';
use feature 'class';
use ECS::Tiny;
use Game::Point;
use Game::Interactive;

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

    field %units = (
        weight => 'g',
        velocity => 'm/s',
        position => 'm',
        height => 'm',
        time => 's',
    );

    method position_to_entities(){ return \%position_to_entities }

    method entity_to_position(){ return \%entity_to_position }

    method names() { return \%names }

    method start($times=undef)
    {
        $self->add_processor(\&get_names);
        $self->add_processor(\&get_positions);
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

        for my($id, $effects) ($self->get_components_by_name('suffers'))
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
}
1;
