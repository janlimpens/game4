package Game::Point;
use v5.38;
use DDP;

use Carp qw(confess croak);
use Scalar::Util qw(looks_like_number);
no warnings 'experimental::builtin';

sub new($class, $x=0, $y=0)
{
    return bless { x => $x, y => $y }, $class
}

sub get_distance($self, $point)
{
    return
        sqrt(
            ($self->{x} - $point->{x})**2
          + ($self->{y} - $point->{y})**2 )
}

sub is_within_distance($self, $point, $distance)
{
    confess 'distance must be positive' unless $distance > 0;
    my $dist = int( $self->get_distance($point) - 0.5 );
    return  $dist <= $distance
}

sub is_within_area($self, $area_begin, $area_end)
{
    return
        $self->{x} >= $area_begin->{x} && $self->{x} <= $area_end->{x}
        &&
        $self->{y} >= $area_begin->{y} && $self->{y} <= $area_end->{y}
}

sub copy($self)
{
    return __PACKAGE__->new($self->{x}, $self->{y})
}

sub add($self, $point)
{
    confess 'point must be defined'
        unless $point;
    $point = __PACKAGE__->from($point)
        if ref($point) ne __PACKAGE__;
    confess 'value unsupported'
        unless $point;
    $self->{x} += $point->{x};
    $self->{y} += $point->{y};
    return $self
}

sub multiply($self, $point)
{
    confess 'multiplier must be defined'
        unless $point;
    $point = __PACKAGE__->from($point)
        if ref($point) ne __PACKAGE__;
    confess 'value unsupported'
        unless $point;
    $self->{x} *= $point->{x};
    $self->{y} *= $point->{y};
    return $self
}

sub get_points_between($self, $point)
{
    confess 'point must be defined'
        unless $point;
    $point = __PACKAGE__->from($point)
        if ref($point) ne __PACKAGE__;
    confess 'value unsupported'
        unless $point;
    return if $self->equals($point);
    my @points;
    my $dx = $point->{x} - $self->{x};
    my $dy = $point->{y} - $self->{y};
    my $steps = abs($dx) > abs($dy) ? abs($dx) : abs($dy);
    my $x_step = $dx / $steps;
    my $y_step = $dy / $steps;
    for my $i (1 .. $steps-1)
    {
        push @points, __PACKAGE__->new(
            $self->{x} + int($x_step * $i + 0.5),
            $self->{y} + int($y_step * $i + 0.5)
        )
    }
    return @points
}

sub equals($self, $point)
{
    return $self->{x} == $point->{x} && $self->{y} == $point->{y}
}

sub key($self)
{
    return "$self->{x}/$self->{y}"
}

sub switch_xy($self)
{
    my $x = $self->{x};
    $self->{x} = $self->{y};
    $self->{y} = $x;
    return $self
}

sub stringify($self)
{
    return $self->key()
}

sub from($class, $value)
{
    my $ref = ref($value);
    my ($x, $y) = !$ref
        ? split '/', $value
        : ref eq 'HASH'
            ? $value->@{qw(x y)}
            : $ref eq 'ARRAY'
                ? $value->@*
                : ();
    croak "$value is not a valid Point"
        if !defined($x//$y) || !looks_like_number($x)  || !looks_like_number($y);
    return $class->new($x, $y)
}

1;
