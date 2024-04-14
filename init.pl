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
        push $components{$_}->@*, $c{$_} for (keys %c);
        return $entity_id
    }

    method get_components_by_id (@entity_id)
    {
        return map { $_, $entities{$_} } @entity_id
    }

    method add_processor (@processor)
    {
        push @processors, $_ for @processor;
        return
    }

    method get_components_by_type (@component_names)
    {
        return
            map { my $e = $_; $_, map { $e->{$_} } @component_names }
            grep { my $e = $_; all { $e->{$_} } @component_names }
            values %entities;
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
    name => 'Bob');

my $e3 = $ctx->add_entity (
    weather => 'nice');

sub move_it ($ctx)
{
    my @components = $ctx->get_components_by_type('position', 'velocity');
    for my ($id, $position, $velocity) (@components)
    {
        $position->{x} += $velocity->{x};
        $position->{y} += $velocity->{y};
    }
    return
}

my @greeted;

sub greet ($ctx)
{
    my @components = $ctx->get_components_by_type('name');
    for my ($id, $name) (@components)
    {
        say STDERR "Hello $name!";
        push @greeted, $name;
    }
    return
}

$ctx->add_processor(\&move_it);
$ctx->add_processor(\&greet);
$ctx->update();

my ($id, $e1_components) = $ctx->get_components_by_id($e1);
is $e1_components->{position}{x}, 1;
is $e1_components->{position}{y}, 1;
is $e1_components->{velocity}{x}, 1;
is $e1_components->{velocity}{y}, 1;
is @greeted, 2, 'all with names have been greeted';

done_testing();
