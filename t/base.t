use Test::More;
use Test::Exception;
use Bio::SubseqIterator qw(score_iterator);

my @sequences = qw(VIKPAPKLK ALEPADD);

my $function = sub {
    return length shift;
};

foreach my $seq (@sequences) {

    my $sliding_score = score_iterator(
        function => $function,
        sequence => \$seq,
        window_size => 2,
        step        => 1,
    );

    is( ref $sliding_score, 'CODE' );

    while ( my $result = $sliding_score->() ) {

        is( ref $result,             'HASH'  );
        is( ref $result->{position}, 'ARRAY' );
        ok( defined $result->{sequence}      );
        ok( defined $result->{score}         );
        is( $result->{score},        2       );

    }

}

sub bad_function {
    die die die; # die!
}

my $can_has_catch = score_iterator(
    function => \&bad_function,
    sequence => \"please don't die",
);

lives_ok { $can_has_catch->() } 'Kaboom?';

done_testing();
