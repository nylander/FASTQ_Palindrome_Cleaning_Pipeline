#! /usr/bin/env perl

use strict;
use warnings;
use POSIX;

######################################################################################
# Script Name:
#   paf_identify_palindrome.pl
#
# Description:
#   Processes PAF alignment files (e.g., from minimap2) to detect
#   self-alignments of reads to their reverse complement (palindromic structures).
#   Outputs overlap statistics and suggested cut positions.
#
# Input:
#   - PAF file from STDIN.
#
# Output (to STDOUT):
#   Original PAF line plus:
#     - overlap proportion
#     - end classification (0=internal, 1=start, 2=end, 3=both)
#     - normalized start and end positions (fraction of read length)
#     - suggested cutoff coordinates
#
# Usage:
#   perl paf_identify_palindrome.pl < input.paf > output.txt
######################################################################################

my %reads = ();

while (<>) {
    chomp;
    my @r = split /\s+/;

    # Only consider reverse self-alignments (query == target, strand == '-')
    if ($r[0] eq $r[5] && $r[4] eq '-') {
        my $start = floor($r[6] * 0.1);
        my $end = floor($r[6] * 0.9);

        my $isend = 0;
        if ($r[2] < $start && $r[3] > $end) {
            $isend = 3;
        }
        elsif ($r[2] < $start) {
            $isend = 1;
        }
        elsif ($r[3] > $end) {
            $isend = 2;
        }

        my $start_pos = sprintf("%.2f", $r[2] / $r[1]);
        my $end_pos = sprintf("%.2f", $r[3] / $r[1]);
        my $overlap_prop = ($r[3] - $r[2]) / $r[1];

        # Keep first/best palindrome hit per read
        if (!$reads{$r[0]}) {
            print "$_\t$overlap_prop\t$isend\t$start_pos\t$end_pos\t";

            if ($isend == 3 || $isend == 2 || $isend == 0) {
                my $cutoff = $r[2] + floor(($r[3] - $r[2]) / 2);
                print "1\t$cutoff\n";
            }
            elsif ($isend == 1) {
                my $cutoff = $r[3] - floor(($r[3] - $r[2]) / 2);
                print "$cutoff\t$r[1]\n";
            }
            else {
                print "1\t$r[1]\n";
            }

            $reads{$r[0]}++;
        }
    }
}
