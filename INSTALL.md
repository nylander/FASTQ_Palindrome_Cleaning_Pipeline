# Install instructions for the FASTQ Palindrome Cleaning Pipeline

The softare [minimap2](https://github.com/lh3/minimap2) should be installed and
available (as `minimap2`) in your PATH.

The two helper scripts
[`paf_identify_palindrome.pl`](scripts/paf_identify_palindrome.pl) and
[`fastq_partition_and_chop_palindrome.pl`](scripts/fastq_partition_and_chop_palindrome.pl)
need to be placed in the same folder as the main script
[`remove_palindrome.sh`](scripts/remove_palindrome.sh).

Workflow tested on Ubuntu Linux 24.04.

Requirements (including versions tested)

- perl v5.38.2
- bash v5.2.21
- minimap2 v2.26-r1175
