use v5.38;
use feature 'class';
use DDP;
no warnings 'experimental';
use List::Util qw(all any);

class Context
{
    no warnings 'experimental::for_list';
    use List::Util qw(all);
    use DDP;

    field %components;
    field %entities;
    field @processors;
    field $next_entity_id = 0;

    method add_entity (%c)
    {
        my $entity_id = $next_entity_id++;
        $entities{$entity_id} = \%c;
        push $components{$_}->@*, $c{$_} for (keys %c);
        return $entity_id
    }

    method get_components_for_entity (@entity_id)
    {
        return map { $entities{$_} } @entity_id
    }

    method entity_has_component ($entity_id, @component_name)
    {
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

my $ctx = Context->new();

my $e1 = $ctx->add_entity (
    name => 'Alice',
    position => { x => 0, y => 0 },
    velocity => 1,
    interactive => 1,);

my $e2 = $ctx->add_entity (
    name => 'Bob',
    position => { x => 5, y => 5 },
    greeter => 1,);

my $e3 = $ctx->add_entity (
    weather => 'nice',
    start => { x => 0, y => 0 },
    end => { x => 10, y => 10 });

my $e4 = $ctx->add_entity (
    weather => 'terrible',
    start => { x => 3, y => 3 },
    end => { x => 6, y => 6 }
);

my %positions;
my %names;

# on_name_changed event
sub get_names ($ctx)
{
    %names = ();
    my @components = $ctx->get_components_by_name('name');
    for my ($id, $name, $position) (@components)
    {
        $names{$id} = $name;
    }
    return
}

# on_position_changed event
sub get_positions ($ctx)
{
    %positions = ();
    my @components = $ctx->get_components_by_name('position');
    for my ($id, $position) (@components)
    {
        push $positions{$position->{x}}{$position->{y}}->@*, $id;
    }
    # p %positions;
    return
}

sub get_weather_at_position($pos, $all_weather, $default='ok')
{
    for my ($end, $start, $weather, $id) ($all_weather->@*)
    {
        return $weather
            if $pos->{x} >= $start
            && $pos->{x} <= $end
            && $pos->{y} >= $start
            && $pos->{y} <= $end
    }
    return $default
}

sub is_adjacent($pos1, $pos2)
{
    return abs($pos1->{x} - $pos2->{x}) <= 1 && abs($pos1->{y} - $pos2->{y}) <= 1
}

sub get_adjacent_entities($pos)
{
    my @adjacent_entities;
    for my $x ($pos->{x} - 1 .. $pos->{x} + 1)
    {
        for my $y ($pos->{y} - 1 .. $pos->{y} + 1)
        {
            push @adjacent_entities, $positions{$x}{$y}->@*
                if exists $positions{$x}{$y};
        }
    }
    return @adjacent_entities
}

sub greet ($ctx)
{
    my $all_weather = [reverse $ctx->get_components_by_name('weather', 'start', 'end')];

    my @greeters = $ctx->get_components_by_name('greeter', 'name', 'position');

    for my ($id, $greeter, $name, $position) (@greeters)
    {
        my @adjacent = grep { $names{$_} } get_adjacent_entities($position);
        next unless @adjacent;
        my $weather = get_weather_at_position($position, $all_weather);
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

sub move_interactively ($ctx)
{
    my @components = $ctx->get_components_by_name(qw(name position velocity interactive));
    for my ($id, $name, $position, $velocity, $interactive) (@components)
    {
        say "Move $name ($id) to where? [n, ne, e, se, s, sw, w, nw]";
        my $bearing = <STDIN>;
        chomp $bearing;
        my %movements = (
            n => [0, 1],
            ne => [1, 1],
            e => [1, 0],
            se => [1, -1],
            s => [0, -1],
            sw => [-1, -1],
            w => [-1, 0],
            nw => [-1, 1],
        );
        if (my $movement = $movements{$bearing})
        {
            $position->{x} += $movement->[0] * $velocity;
            $position->{y} += $movement->[1] * $velocity;
            say "$name moved to $position->{x}, $position->{y}";
        } else {
            say "Invalid bearing: $bearing";
        }
    }
    return
}

my $stop_it = 0;
$SIG{INT} = sub { $stop_it = 1 };

$ctx->add_processor(\&get_names);
$ctx->add_processor(\&move_interactively);
$ctx->add_processor(\&get_positions);
$ctx->add_processor(\&greet);

until ($stop_it)
{
    $ctx->update()
        unless $stop_it;
}
