#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 15 March 2020
# https://github.com/trizen

# Given `n` and `p`, count the number of integers k <= n, such that:
#    gpf(k) = p
# where `gpf(k)` is the greatest prime factor of k.

use 5.020;
use integer;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub count_with_gpf ($n, $p) {

    my $count = 0;

    sub ($m, $q) {

        my $t = logint($m, $p);

        if ($t == 0) {
            return;
        }

        if ($q == $p) {
            $count += $t;
            return;
        }

        my $w = logint($m, $q);

        if ($w == 1) {
            $count += 1;
            return;
        }

        foreach my $k (0 .. $w) {

            my $v = divint($m, powint($q, $k));
            my $s = next_prime($q);

            __SUB__->($v, $s);
        }
    }->($n, 2);

    return $count;
}

foreach my $n (1 .. 10) {
    say "a(10^$n) for primes below 20: {", join(', ', map { count_with_gpf(powint(10, $n), $_) } @{primes(20)}), "}";
}

__END__
a(10^1)  for primes below 20: {3, 3, 2, 1, 0, 0, 0, 0}
a(10^2)  for primes below 20: {6, 13, 14, 12, 9, 7, 5, 5}
a(10^3)  for primes below 20: {9, 30, 46, 55, 51, 50, 45, 44}
a(10^4)  for primes below 20: {13, 53, 108, 163, 184, 211, 212, 224}
a(10^5)  for primes below 20: {16, 84, 212, 381, 503, 651, 731, 840}
a(10^6)  for primes below 20: {19, 122, 365, 766, 1159, 1674, 2073, 2572}
a(10^7)  for primes below 20: {23, 166, 578, 1387, 2365, 3769, 5100, 6809}
a(10^8)  for primes below 20: {26, 217, 861, 2322, 4411, 7681, 11290, 16141}
a(10^9)  for primes below 20: {29, 276, 1224, 3664, 7673, 14498, 22986, 35060}
a(10^10) for primes below 20: {33, 342, 1677, 5522, 12618, 25721, 43765, 70947}
