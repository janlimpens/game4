package ECS::Tiny;
use v5.38;
no warnings 'experimental::class';
use feature qw(class);

class ECS::Tiny::Context
{
    no warnings 'experimental::for_list';
    use List::Util qw(all any);
    use DDP;

    field %entities;
    field @processors;
    field $next_entity_id = 0;

    method add_entity (%c)
    {
        my $entity_id = $next_entity_id++;
        $entities{$entity_id} = \%c;
        return $entity_id
    }

    method remove_entity(@entity)
    {
        delete $entities{$_} for @entity;
        return
    }

    method add_component($entity, %components)
    {
        $entities{$entity} = {
            $entities{$entity}->%*,
            %components, # we need better merging
        };
        return
    }

    method get_components_for_entity (@entity_id)
    {
        return map { $entities{$_} } @entity_id
    }

    method entity_has_component ($entity_id, @component_name)
    {
        return unless @component_name;
        return unless exists $entities{$entity_id};
        return all { exists $entities{$entity_id}->{$_} } @component_name
    }

    method add_processor (@processor)
    {
        push @processors, $_ for @processor;
        return
    }

    method get_components_by_name (@component_names)
    {
        return
            map { my $e = $_; $e => map { $entities{$e}->{$_} } @component_names }
            sort
            grep { my $e = $_; all { exists $entities{$e}->{$_} } @component_names }
            keys %entities;
    }

    method update ()
    {
        $_->($self) for @processors;
        return
    }
}
