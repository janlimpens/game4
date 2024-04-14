use v5.38;
use feature 'class';
use Test2::V0;
use DDP;
no warnings 'experimental';

class Context
{
    no warnings 'experimental::for_list';
    use List::Util qw(all);

    field %components;
    field %entities;
    field @processors;
    field $next_entity_id = 0;

    method add_entity (%c)
    {
        my $entity_id = $next_entity_id++;
        $entities{$entity_id} = \%c;
        for my $key (keys %c)
        {
            push $components{$key}->@*, $c{$key};
        }
        return $entity_id
    }

    method get_entity ($entity_id)
    {
        return $entities{$entity_id}
    }

    method add_processor ($processor)
    {
        push @processors, $processor;
        return
    }

    method get_components (@component_names)
    {
        return ($components{$component_names[0]} // [])->@*
            if @component_names == 1;

        my @components =
            map { my $e = $_; map { $e->{$_} } @component_names }
            grep { my $e = $_; all { $e->{$_} } @component_names }
            values %entities;

        return @components
    }

    method update ()
    {
        for my $processor (@processors)
        {
            $processor->($self);
        }
        return
    }
}

my $ctx = Context->new();

my $e1 = $ctx->add_entity (
    name => 'Alice',
    position => { x => 0, y => 0 },
    velocity => { x => 1, y => 1 });

my $e2 = $ctx->add_entity (
    name => 'Bob');

my $e3 = $ctx->add_entity (
    weather => 'nice');

sub move_it ($ctx)
{
    my @components = $ctx->get_components('position', 'velocity');
    for my ($position, $velocity) (@components)
    {
        $position->{x} += $velocity->{x};
        $position->{y} += $velocity->{y};
    }
    return
}

my @greeted;

sub greet ($ctx)
{
    my @components = $ctx->get_components('name');
    @components;
    for my ($name) (@components)
    {
        say STDERR "Hello $name!";
        push @greeted, $name;
    }
    return
}

$ctx->add_processor(\&move_it);
$ctx->add_processor(\&greet);
$ctx->update();

my $e1_components = $ctx->get_entity($e1);
is $e1_components->{position}{x}, 1;
is $e1_components->{position}{y}, 1;
is $e1_components->{velocity}{x}, 1;
is $e1_components->{velocity}{y}, 1;
is @greeted, 2, 'all with names have been greeted';

done_testing();
