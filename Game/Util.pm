use v5.38;
use DDP;
use Exporter 'import';
our @EXPORT = qw(take_n);

sub take_n ($n, @list)
{
    my @result;
    while (my @slice = splice @list, 0, $n)
    {
        push @result, \@slice;
    }
    return @result
}

1;
