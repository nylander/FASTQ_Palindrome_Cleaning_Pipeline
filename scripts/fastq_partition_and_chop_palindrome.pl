#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use IO::Compress::Gzip qw(gzip $GzipError);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use IO::File;
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

my $SCRIPT_NAME = basename($0);

=pod

=head1 NAME

fastq_partition_and_chop_palindrome.pl

=head1 VERSION

0.1

=head1 SYNOPSIS

 fastq_partition_and_chop_palindrome.pl [options] coords_file fastq_file min_length

 Options:
   -h  help message
   -v  version

 Positional arguments:
   coords_file    tsv-formatted input file
   fastq_file     input fastq file
   min_length     minimum fragment length to retain

=head1 OPTIONS

=over 4

=item B<-h,--help>

Prints help message and exits.

=item B<-v,--version>

Prints the version and exits.

=back

=head1 EXAMPLE

C<< fastq_partition_and_chop_palindrome.pl coords.tsv testdata.fastq 1000 >>

=head1 DESCRIPTION

Processes FASTQ reads using palindrome and chop information from a
coordinate file. Palindromic reads are split, fragments shorter than a
user-defined minimum length are discarded. Non-palindromic reads are
kept unchanged.

Original source: L<YiChen Lee|https://yichienlee1010.github.io/script/>

=head2 INPUT

Processes the following B<positional> arguments in order

=over 4

=item *

B<coords_file> tab-delimited file with read IDs and chop coordinates

=item *

B<fastq_file> input FASTQ file (can be compressed, .gz)

=item *

B<min_length> minimum fragment length to retain (bp)

=back

=head2 OUTPUT

Two files in fastq format:

=over 4

=item *

B<fastq_file.include.fastq>: reads without palindromes (kept as-is).
File name is based on the input F<fastq_file> basename.

=item *

B<fastq_file.exclude.fastq> : chopped fragments from palindromic reads
File name is based on the input F<fastq_file> basename.

=back

=head1 LICENSE

L<MIT|https://opensource.org/license/mit/>

=cut

my $help;
my $version;

GetOptions('h|help' => \$help, 'v|version' => \$version);# or pod2usage(-verbose => 0);
pod2usage(-verbose => 2) if $help;
pod2usage(-verbose => 99, -sections => "VERSION") if $version;

if ( @ARGV != 3 ) {
    print "Error: program requires 3 arguments\n";
    pod2usage(-verbose => 0);
    exit;
}

my $read_file = $ARGV[0];
my $fastq_file = $ARGV[1];
my $min_len = $ARGV[2];
my ($basename, $dir, $in_ext);
my $chopped = 0;
my $palindrome_middle = 0;
my $ignored = 0;
my %reads;

# Load chop coordinates from read file
open(my $RF, "$read_file") or die "Error: Unable to open $read_file\n";
while (<$RF>) {
    chomp;
    my @r = split /\s+/;

    if ($r[18] != 0) {
        $reads{"\@$r[0]"} = "$r[21]\t$r[22]\t$r[18]\t$r[1]";
        $chopped++;
    }
    elsif ($r[19] > 0.3) {
        $reads{"\@$r[0]"} = "$r[21]\t$r[22]\t$r[18]\t$r[1]";
        $palindrome_middle++;
    }
    else {
        $ignored++;
    }
}
close $RF;

print STDERR "==== To chop: $chopped, palindrome at middle: $palindrome_middle, ignored: $ignored\n";

# Is input compressed? Check twice.
my $is_gz = ($fastq_file =~ /\.gz$/);

if ($is_gz) {
    ($basename, $dir, $in_ext) = fileparse($fastq_file, qr/\.[^.]*\.gz/);
}
else {
    ($basename, $dir, $in_ext) = fileparse($fastq_file, qr/\.[^.]*/);
    if (open my $test, '<', $fastq_file) {
        read $test, my $magic, 2;
        close $test;
        $is_gz = ($magic eq "\x1f\x8b");
    }
}

# Open input and output fastq files
my $include_file = $basename . ".include" . $in_ext;
my $exclude_file = $basename . ".exclude" . $in_ext;
my $FASTQ;
my $OUT_INCLUDE;
my $OUT_EXCLUDE;

if ($is_gz) {
    $FASTQ = IO::Uncompress::Gunzip->new($fastq_file) or die "Error: gunzip failed for '$fastq_file': $GunzipError\n";
    $OUT_INCLUDE = IO::Compress::Gzip->new($include_file) or die "Error: gzip failed for '$include_file': $GzipError\n";
    $OUT_EXCLUDE = IO::Compress::Gzip->new($exclude_file) or die "Error: gzip failed for '$exclude_file': $GzipError\n";
}
else {
    $FASTQ = IO::File->new($fastq_file, "r") or die "Error: Unable to read '$fastq_file': $!\n";
    $OUT_INCLUDE = IO::File->new(">$include_file") or die "Error: can't open '$include_file': $!\n";
    $OUT_EXCLUDE = IO::File->new(">$exclude_file") or die "Error: can't open '$exclude_file': $!\n";
}

# Process FASTQ entries
while (<$FASTQ>) {
    my $name = $_;
    my $seq = <$FASTQ>;
    my $tmp = <$FASTQ>;
    my $qual = <$FASTQ>;

    chomp($seq);
    chomp($qual);

    my ($seqname) = ($name =~ /(^\@\S+)/);

    if ($reads{$seqname}) {
        my @regions = split /\t/, $reads{$seqname};
        my $type = $regions[2];
        my $origlen = $regions[3];
        my ($newseq, $newqual, $newseq2, $newqual2);
        my $seqname2 = $seqname;

        if ($type == 1) {
            $seqname2 = "$seqname-dup1.2";
            $seqname = "$seqname-dup1.1";
            $newseq = substr $seq, 0, $regions[0];
            $newqual = substr $qual, 0, $regions[0];
            $newseq2 = substr $seq, $regions[0];
            $newqual2 = substr $qual, $regions[0];
        }
        else {
            $seqname2 = "$seqname-dup023.2";
            $seqname = "$seqname-dup023.1";
            $newseq = substr $seq, 0, $regions[1];
            $newqual = substr $qual, 0, $regions[1];
            $newseq2 = substr $seq, $regions[1];
            $newqual2 = substr $qual, $regions[1];
        }

        if (length($newseq) >= $min_len) {
            print $OUT_EXCLUDE "$seqname\n$newseq\n$tmp$newqual\n";
        }

        if (length($newseq2) >= $min_len) {
            print $OUT_EXCLUDE "$seqname2\n$newseq2\n$tmp$newqual2\n";
        }
    }
    else {
        print $OUT_INCLUDE "$seqname\n$seq\n$tmp$qual\n";
    }
}

$FASTQ->close;
$OUT_INCLUDE->close;
$OUT_EXCLUDE->close;

print STDERR "==== End of script $SCRIPT_NAME\n";
