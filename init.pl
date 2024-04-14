use v5.38;
use feature 'class';
use Test2::V0;
use DDP;
no warnings 'experimental';

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
    velocity => { x => 1, y => 1 });

my $e2 = $ctx->add_entity (
    name => 'Bob',
    position => { x => 5, y => 5 },);

my $e3 = $ctx->add_entity (
    weather => 'nice',
    start => { x => 0, y => 0 },
    end => { x => 10, y => 10 });

my $e4 = $ctx->add_entity (
    weather => 'terrible',
    start => { x => 3, y => 3 },
    end => { x => 6, y => 6 }
);

sub move_it ($ctx)
{
    my @components = $ctx->get_components_by_name('position', 'velocity');
    # p @components, as => 'components movit';
    for my ($id, $position, $velocity) (@components)
    {
        $position->{x} += $velocity->{x};
        $position->{y} += $velocity->{y};
    }
    return
}

my @greeted;
my %got_weather;

sub get_weather_at_position($x, $y, $all_weather, $default='ok')
{
    for my ($end, $start, $weather, $id) ($all_weather->@*)
    {
        if ($x >= $start->{x} && $x <= $end->{x} &&
            $y >= $start->{y} && $y <= $end->{y})
        {
            $got_weather{$id} = 1;
            return $weather
        }
    }
    return $default
}

sub greet ($ctx)
{
    my @weather = reverse $ctx->get_components_by_name('weather', 'start', 'end');
    my @components = $ctx->get_components_by_name('name', 'position');
    for my ($id, $name, $position) (@components)
    {
        my ($components) = $ctx->get_components_for_entity($id);
        my $position = $components->{position};
        my $weather = $position
            ? get_weather_at_position($position->{x}, $position->{y}, \@weather)
            : undef;
        say STDERR $weather
            ? "Hello $name! The weather is $weather, today."
            : "Hello $name!";
        push @greeted, $name;
    }
    return
}

my $stop_it = 0;
$SIG{INT} = sub { $stop_it = 1 };

$ctx->add_processor(\&move_it);
$ctx->add_processor(\&greet);

until ($stop_it)
{
    $ctx->update();
}
# my ($e1_components) = $ctx->get_components_for_entity($e1);
# is $e1_components->{position}{x}, 1;
# is $e1_components->{position}{y}, 1;
# is $e1_components->{velocity}{x}, 1;
# is $e1_components->{velocity}{y}, 1;
# is @greeted, 2, 'all with names have been greeted';

done_testing();
