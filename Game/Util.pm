use v5.38;
use DDP;
use Exporter 'import';
our @EXPORT = qw(take);

sub take ($n, @list)
{
    my @result;
    while (my @slice = splice @list, 0, $n)
    {
        push @result, \@slice;
    }
    return @result
}

sub nth ($n, @list)
{
    map { $_->[$n-1] }
    take( $n, @list )
}

1;
