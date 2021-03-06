#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 09 October 2019
# https://github.com/trizen

# Optimize JPEG and PNG images in a given directory (recursively) using the "jpegoptim" and "optipng" tools.

use 5.020;
use warnings;
use File::Find qw(find);
use experimental qw(signatures);
use File::MimeInfo::Magic qw();

my $batch_size = 100;    # how many files to process at once

sub optimize_JPEGs (@files) {

    say ":: Optimizing a batch of ", scalar(@files), " JPEG images...";

    system(
           "jpegoptim",
           "--preserve",    # preserve file modification times
           ##'--max=90',
           ##'--size=2048',
           '--all-progressive',
           @files
          );
}

sub optimize_PNGs (@files) {

    say ":: Optimizing a batch of ", scalar(@files), " PNG images...";

    system(
           "optipng",
           "-preserve",    # preserve file attributes if possible
           "-o1",          # optimization level
           @files
          );
}

my %types = (
             'image/jpeg' => {
                              files => [],
                              call  => \&optimize_JPEGs,
                             },
             'image/png' => {
                             files => [],
                             call  => \&optimize_PNGs,
                            },
            );

@ARGV or die "usage: perl script.pl [dirs | files]\n";

find(
    {
     no_chdir => 1,
     wanted   => sub {

         (-f $_) || return;
         my $type = File::MimeInfo::Magic::magic($_) // return;

         if (exists $types{$type}) {

             my $ref = $types{$type};
             push @{$ref->{files}}, $_;

             if (scalar(@{$ref->{files}}) >= $batch_size) {
                 $ref->{call}->(splice(@{$ref->{files}}));
             }
         }
     }
    } => @ARGV
);

foreach my $type (keys %types) {

    my $ref = $types{$type};

    if (@{$ref->{files}}) {
        $ref->{call}->(splice(@{$ref->{files}}));
    }
}

say ":: Done!";
