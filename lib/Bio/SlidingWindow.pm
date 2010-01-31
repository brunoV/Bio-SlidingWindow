package Bio::SlidingWindow;

# ABSTRACT: Apply a function to a sequence sliding window

use Modern::Perl;
use Try::Tiny;
use Sub::Exporter -setup => { exports => [qw(subsequence_iterator score_iterator)] };

=method score_iterator

Take a function that gives a score to a peptide, a polypeptide sequence,
a window size and a step and returns an iterator that will give the
score for each sequence substring.

    my $sliding_score = score_iterator(
        function => $function,
        sequence => \$seq,
        window_size => 2,
        step        => 1,
    );

    while ( my $result = $sliding_score->() ) {

        say $result->{position}; # [ $start, $end ]
        say $result->{sequence}; # $sequence
        say $result->{score};    # $score
    }

=cut

sub score_iterator {
    my %args = @_;

    # Take a function that gives a score to a peptide, a polypeptide
    # sequence, a window size and a step and returns an iterator that
    # will give the score for each sequence substring.


    my $f       = $args{function}    // die "Need a coderef";
    my $seq_ref = $args{sequence}    // die "Need a sequence ref";
    my $w       = $args{window_size} //= 7;
    my $s       = $args{step}        //= 1;

    unless (ref $f eq 'CODE') { die "function is not a sub reference" }

    unless (ref $seq_ref eq 'SCALAR') {
        die "sequence is not a scalar reference"
    }

    my $pos = 1;
    my $it = subsequence_iterator( $seq_ref, $w, $s );

    return sub {
        my %result;

        my $peptide = $it->() || return;

        # Save the sequence
        $result{sequence} =  $peptide;

        # Calculate the score
        my $score = try { $f->($peptide) };
        $score //= 'NaN';
        $result{score} = $score;

        # Save the initial and final positions of the peptide
        $result{position} = [ $pos, $pos + $w - 1 ];
        $pos += $s;

        return \%result;
    }

}

=method subsequence_iterator

Takes a reference to a sequence, a window size and a sliding step as
arguments. Returns an iterator that will return the correct subsequence
when kicked, and undef when exhausted.

    my $sequence = 'AAAAAAGGGGGG';

    my $it = subsequence_iterator(\$sequence, 6, 6);

    while (my $subseq = $it->()) {
        print $subseq, " ";
    }

    # OUTPUT: "AAAAAA GGGGGG "

=cut

sub subsequence_iterator {
    my ( $seq_ref, $window_size, $step ) = @_;
    my $position = 0;
    return sub {
        no warnings;
        my $substr = substr( $$seq_ref, $position, $window_size );
        $position += $step;

        if ( length $substr == $window_size ) { return $substr }
    }
}

1;
