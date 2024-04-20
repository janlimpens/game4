package Game::Point;
use v5.38;
use DDP;

use Carp qw(confess croak);

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

sub add($self, $point)
{
    $point = __PACKAGE__->from($point)
        if ref($point) ne __PACKAGE__;
    $self->{x} += $point->{x};
    $self->{y} += $point->{y};
    return $self
}

sub equals($self, $point)
{
    return $self->{x} == $point->{x} && $self->{y} == $point->{y}
}

sub key($self)
{
    return "$self->{x}/$self->{y}"
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
        if !defined($x//$y) || $x =~ /\D/ || $y =~ /\D/;
    return $class->new($x, $y)
}

1;
