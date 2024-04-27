use v5.38;
use lib '.';
no warnings 'experimental::class';
use feature 'class';

class Game::Interactive
{
    no warnings qw(experimental);
    use Carp;
    use DDP;
    use List::Util qw(any);

    field $ctx :param;
    field %last_action;

    method dispatch()
    {
        my @components = $ctx->get_components_by_name(qw(interactive name position));
        for my ($id, $interactive, $name, $position) (@components)
        {
            my $action;
            my @args;
            until ($action)
            {
                $self->look_around($id, 1);
                say sprintf 'What should %s do? [%s]', $name, join ', ', sort keys $interactive->%*;
                my $input = <STDIN>;
                chomp $input;
                my ($a, @a) = split ' ', ($input//'');
                $a //= '';
                if ($a eq '' && exists $last_action{$id})
                {
                    ($action, @args) = $last_action{$id}[-1]->@*;
                    say sprintf 'Repeating last action: %s %s', $action, join ' ', @args;
                    # p $last_action{$id}, as => 'last_action';
                }
                elsif (exists $interactive->{$a}) {
                    ($action, @args) = ($a, @a);
                } else {
                    say "I can't do that ($a)!";
                }
            }
            push $last_action{$id}->@*, [$action, @args];
            # say "Action: $action with args: @args";
            my %actions = (
                accelerate => method { say "Accelerate!" },
                climb => method { say "Climb!" },
                close => method { my ($door, $key) = @args; $self->open($id, $door, 'close', $key)},
                dump => method { $ctx->dump(@args) },
                eat => method { my ($food) = @args; $self->eat($id, $food) },
                give => method { say "Give!" },
                go_to => method { my ($target) = @args; $ctx->go_to($id, $target) },
                inspect => method { say "Inspect!" },
                look_around => method { $self->look_around($id) },
                move => method { my ($dir) = @args; $self->move($id, $dir) },
                open => method { my ($door, $key) = @args; $self->open($id, $door, 'open', $key) },
                quit => method { say "Goodbye!"; $ctx->stop() },
                sleep => method { say "Sleep!" },
                take => method { my ($item) = @args; $self->take($id, $item) },
                throw => method { say "Throw!" },
            );
            $actions{$action}->($self, $id, @args);
        }
    }

    method open ($entity, $item, $action='open', $key=undef)
    {
        confess 'Action can be either open or close!'
            unless $action eq 'open' || $action eq 'close';
        my $name = $ctx->get_name($entity);
        if (!$ctx->is_within_distance($entity, $item, 1))
        {
            say "$name can't reach that!";
            return
        }
        my ($c, $ci) = $ctx->get_components_for_entity($entity, $item);
        my $item_name = $ctx->get_name($item);
        my $action_name = $action eq 'open' ? 'opens' : 'closes';
        return if $ci->{key} && $ci->{key} ne $key;
        if ($ci && $ci->{opens})
        {
            $ci->{collides} = $action eq 'open' ? 0 : 1;
            say "$name $action_name $item_name.";
        } else {
            say "$name can't open that!";
        }
        return
    }

    method take ($entity, $item)
    {
        my $give_up = 0;
        until ($item || $give_up) {
            say "What would you like to take?";
            my $i = <STDIN>;
            chomp $i;
            $give_up = 1 && next()
                if $i eq '';
            $item = $i
                if $ctx->entity_has_component($entity, 'weight');
        }
        my ($c, $ci) = $ctx->get_components_for_entity($entity, $item);
        my $distance = $ctx->entity_to_position()->{$entity}->get_distance($ctx->entity_to_position()->{$item});
        if ($distance > 1)
        {
            say "You can't reach that from here!";
            return
        }
        my $name = $ctx->names()->{$entity} // 'Entity';
        if ($ci && $ci->{weight})
        {
            my $item_name = $ctx->names()->{$item} // 'item';
            $ctx->remove_component($item, 'position');
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
        my ($c, $ci) = $ctx->get_components_for_entity($entity, $item);
        my $inventory = $c->{inventory} // {};
        my $name = $ctx->names()->{$entity} // 'Entity';
        my $food_name = $ctx->names()->{$item} // 'item';
        unless ($inventory->{$item})
        {
            say "$name doesn't have $food_name!";
            return
        }
        if ($ci && $ci->{food})
        {
            my $item_name = $ctx->names()->{$item} // 'item';
            say "$name eats $item_name";
            $c->{weight} -= $ci->{weight}
                if $c->{weight} && $ci->{weight};
            $ctx->remove_entity($item);
            if (my $effects = $ci->{effects})
            {
                $c->{suffers} = $effects;
                say "$name feels something..."
            }
        } else {
            say "$name can't eat that!";
        }
        return
    }

    method move ($entity, $movement=undef)
    {
        my $name = $ctx->names()->{$entity} // 'Entity';
        until ($movement && $ctx->movements()->{$movement})
        {
            say "Move $name ($entity) to where? [n, ne, e, se, s, sw, w, nw]";
            my $dir = <STDIN>;
            chomp $dir;
            $movement = $dir if $self->movements()->{$dir}
        }
        my ($c) = $ctx->get_components_for_entity($entity);
        my $current_pos = $c->{position};
        confess 'No position for entity!'
            unless $current_pos;
        my $velocity = $c->{velocity} //= 1;
        $ctx->move_entity($entity, $current_pos, $velocity, $movement);
        say "$name is now at [$c->{position}{x}/$c->{position}{y}]";
        return
    }

    method look_around ($entity, $distance=10)
    {
        my ($c) = $ctx->get_components_for_entity($entity);
        return unless $c->{position};
        my $position = bless $c->{position} => 'Game::Point';
        my %adjacent =
            map {
                my $name = $ctx->names()->{$_};
                $name
                    ? ("$name ($_)" => (bless $ctx->entity_to_position()->{$_}, 'Game::Point'))
                    : ()
            }
            grep { $_ != $entity }
            $ctx->get_adjacent_entities($position, $distance);
        my $name = $ctx->names()->{$entity};
        if (%adjacent)
        {
            say sprintf '%s sees: %s',
            $name,
            join "\n",
            map { "$_ at [$adjacent{$_}{x}/$adjacent{$_}{y}]" }
            keys %adjacent;
        } else {
            say "$name can see nothing of importance.";
        }

        return \%adjacent
    }
}
