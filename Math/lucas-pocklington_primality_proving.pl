#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 10 January 2020
# https://github.com/trizen

# Prove the primality of a number N, using the Lucas `U` sequence and the Pocklington primality test, recursively factoring N-1 and N+1 (whichever is easier to factorize first).

# See also:
#   https://en.wikipedia.org/wiki/Pocklington_primality_test
#   https://en.wikipedia.org/wiki/Primality_certificate
#   http://mathworld.wolfram.com/PrattCertificate.html
#   https://math.stackexchange.com/questions/663341/n1-primality-proving-is-slow

use 5.020;
use strict;
use warnings;
use experimental qw(signatures);

use List::Util qw(uniq);
use ntheory qw(is_prime is_prob_prime);
use Math::Prime::Util::GMP qw(ecm_factor is_strong_pseudoprime);

use Math::AnyNum qw(
  :overload prod primorial is_coprime powmod
  irand min is_square lucasUmod gcd kronecker
  );

my $TRIAL_LIMIT = 10**6;
my $primorial   = primorial($TRIAL_LIMIT);

sub trial_factor ($n) {

    my @f;
    my $g = gcd($primorial, $n);

    if ($g > 1) {
        my @primes = ntheory::factor($g);
        foreach my $p (@primes) {
            while ($n % $p == 0) {
                push @f, $p;
                $n /= $p;
            }
        }
    }

    return ($n, @f);
}

sub lucas_pocklington_primality_proving ($n, $lim = 2**64) {

    if ($n <= $lim or $n <= 2) {
        return is_prime($n);    # fast deterministic test for small n
    }

    is_prob_prime($n) || return 0;

    if (ref($n) ne 'Math::AnyNum') {
        $n = Math::AnyNum->new("$n");
    }

    my $nm1 = $n - 1;
    my $np1 = $n + 1;

    my ($B1, @f1) = trial_factor($nm1);
    my ($B2, @f2) = trial_factor($np1);

    if (prod(@f1) < $B1 and prod(@f2) < $B2) {
        if ($B1 < $B2) {
            if (__SUB__->($B1)) {
                push @f1, $B1;
                $B1 = 1;
            }
            elsif (__SUB__->($B2)) {
                push @f2, $B2;
                $B2 = 1;
            }
        }
        else {
            if (__SUB__->($B2)) {
                push @f2, $B2;
                $B2 = 1;
            }
            elsif (__SUB__->($B1)) {
                push @f1, $B1;
                $B1 = 1;
            }
        }
    }

    my $pocklington_primality_proving = sub {

        foreach my $p (uniq(@f1)) {
            for (; ;) {
                my $a = irand(2, $nm1);
                is_strong_pseudoprime($n, $a) || return 0;
                if (is_coprime(powmod($a, $nm1 / $p, $n) - 1, $n)) {
                    say "a = $a ; p = $p";
                    last;
                }
            }
        }

        return 1;
    };

    my $find_PQD = sub {

        my $l = min(10**9, $n - 1);

        for (; ;) {
            my $P = (irand(1, $l));
            my $Q = (irand(1, $l) * ((rand(1) < 0.5) ? 1 : -1));
            my $D = ($P * $P - 4 * $Q);

            next if is_square($D % $n);
            next if ($P >= $n);
            next if ($Q >= $n);
            next if (kronecker($D, $n) != -1);

            return ($P, $Q, $D);
        }
    };

    my $lucas_primality_proving = sub {
        my ($P, $Q, $D) = $find_PQD->();

        is_strong_pseudoprime($n, $P + 1) or return 0;
        lucasUmod($P, $Q, $np1, $n) == 0  or return 0;

        foreach my $p (uniq(@f2)) {
            for (; ;) {
                $D == ($P * $P - 4 * $Q) or die "error: $P^2 - 4*$Q != $D";

                if ($P >= $n or $Q >= $n) {
                    return __SUB__->();
                }

                if (is_coprime(lucasUmod($P, $Q, $np1 / $p, $n), $n)) {
                    say "P = $P ; Q = $Q ; p = $p";
                    last;
                }

                ($P, $Q) = ($P + 2, $P + $Q + 1);
                is_strong_pseudoprime($n, $P) || return 0;
            }
        }

        return 1;
    };

    for (; ;) {
        my $A1 = prod(@f1);
        my $A2 = prod(@f2);

        if ($A1 > $B1 and is_coprime($A1, $B1)) {
            say "\n:: N-1 primality proving of: $n";
            return $pocklington_primality_proving->();
        }

        if ($A2 > $B2 and is_coprime($A2, $B2)) {
            say "\n:: N+1 primality proving of: $n";
            return $lucas_primality_proving->();
        }

        my @ecm_factors = map { Math::AnyNum->new($_) } ecm_factor($B1 * $B2);

        foreach my $p (@ecm_factors) {

            if ($B1 % $p == 0 and __SUB__->($p, $lim)) {
                while ($B1 % $p == 0) {
                    push @f1, $p;
                    $A1 *= $p;
                    $B1 /= $p;
                }
                if (__SUB__->($B1, $lim)) {
                    push @f1, $B1;
                    $A1 *= $B1;
                    $B1 /= $B1;
                }
                last if ($A1 > $B1);
            }

            if ($B2 % $p == 0 and __SUB__->($p, $lim)) {
                while ($B2 % $p == 0) {
                    push @f2, $p;
                    $A2 *= $p;
                    $B2 /= $p;
                }
                if (__SUB__->($B2, $lim)) {
                    push @f2, $B2;
                    $A2 *= $B2;
                    $B2 /= $B2;
                }
                last if ($A2 > $B2);
            }
        }
    }
}

say "Is prime: ",
  lucas_pocklington_primality_proving(115792089237316195423570985008687907853269984665640564039457584007913129603823);

__END__
:: N+1 proving primality of: 924116845936603030416149
P = 10567831 ; Q = -155247471 ; p = 2
P = 10567833 ; Q = -144679639 ; p = 3
P = 10567835 ; Q = -134111805 ; p = 5
P = 10567835 ; Q = -134111805 ; p = 23
P = 10567835 ; Q = -134111805 ; p = 839
P = 10567835 ; Q = -134111805 ; p = 319260971804461153

:: N-1 proving primality of: 145206169609764066844927343258645146513471
a = 23894587943149951374726105040167080972119 ; p = 2
a = 9772693580804527639015567377711269934690 ; p = 3
a = 22088050125342044192501465186577989942608 ; p = 5
a = 100434861748661459816589403216151015231441 ; p = 13
a = 79980763258385906480313921736470483070576 ; p = 37
a = 84529173890417750498796788376074320808743 ; p = 5419
a = 88838252951406394412298220801457344790792 ; p = 2009429159
a = 17636365694776840117330941332548551892464 ; p = 924116845936603030416149

:: N-1 proving primality of: 767990784468614637092681680819989903265059687929
a = 3842272248666310527359382981869204879717370085 ; p = 2
a = 253060566414177618210771214819506662278894996085 ; p = 661121
a = 63667205940523067515972047917139026914055648712 ; p = 145206169609764066844927343258645146513471

:: N+1 proving primality of: 1893865274499603695070553024902095101451637190432913
P = 636453740 ; Q = 264637600 ; p = 2
P = 636453740 ; Q = 264637600 ; p = 3
P = 636453740 ; Q = 264637600 ; p = 137
P = 636453740 ; Q = 264637600 ; p = 767990784468614637092681680819989903265059687929

:: N+1 proving primality of: 57896044618658097711785492504343953926634992332820282019728792003956564801911
P = 855767016 ; Q = 2559955057 ; p = 2
P = 855767016 ; Q = 2559955057 ; p = 3
P = 855767016 ; Q = 2559955057 ; p = 1669
P = 855767016 ; Q = 2559955057 ; p = 14083
P = 855767016 ; Q = 2559955057 ; p = 1857767
P = 855767016 ; Q = 2559955057 ; p = 29170630189
P = 855767016 ; Q = 2559955057 ; p = 1893865274499603695070553024902095101451637190432913

:: N-1 proving primality of: 115792089237316195423570985008687907853269984665640564039457584007913129603823
a = 10079070086066905391578067611875961110383905750203796829265924540693889788826 ; p = 2
a = 38895332959091919723875074368716140325907319500319994475550376684837507720541 ; p = 57896044618658097711785492504343953926634992332820282019728792003956564801911
Is prime: 1
