use v5.38;
use lib '.';
no warnings 'experimental::class';
use feature 'class';

class Game::Interactive
{
    no warnings qw(experimental);

    field $ctx :param;
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

    method dispatch()
    {
        my @components = $ctx->get_components_by_name(qw(interactive name position));
        for my ($id, $interactive, $name, $position) (@components)
        {
            my $action;
            my @args;
            until ($action)
            {
                say sprintf "$name is at %s.", $position->stringify();
                say sprintf 'What should %s do? [%s]', $name, join ', ', sort keys $interactive->%*;
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
                quit => method { say "Goodbye!"; $ctx->stop() },
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
        } else {
            say "$name can't eat that!";
        }
        return
    }

    method move_interactively ($entity, $movement)
    {
        my ($c) = $ctx->get_components_for_entity($entity);
        my %c = $c ? $c->%* : ();
        my $velocity = $c{velocity} //= { x => 0, y => 0 };
        my $name = $ctx->names()->{$entity} // 'Entity';
        until ($movement && $movements{$movement})
        {
            say "Move $name ($entity) to where? [n, ne, e, se, s, sw, w, nw]";
            my $dir = <STDIN>;
            chomp $dir;
            $movement = $dir if $movements{$dir}
        }
        my $offset = $movements{$movement};
        $c{position} = bless $c{position} => 'Game::Point';
        $c{position}->add($offset);
        say "$name is now at [$c{position}{x}/$c{position}{y}]";
        return
    }

    method look_around ($entity, $distance=10)
    {
        my ($c) = $ctx->get_components_for_entity($entity);
        return unless $c->{position};
        my $position = bless $c->{position}, 'Game::Point';
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
