# FASTQ Palindrome Cleaning Pipeline

## Description

Detects and removes palindromic reads from [ONT
FASTQ](https://epi2me.nanoporetech.com/notebooks/Introduction_to_fastq_file.html)
files.

Original scripts are from [YiChen Lee](https://yichienlee1010.github.io/script/).
From the original description:

> Through [Minimap2](https://github.com/lh3/minimap2) alignments, we identified
> artificial palindromic sequences, described as reads that map to the reverse
> complement version of themselves.  These palindromic sequences were extracted
> from raw reads and corrected by dividing the read from the midpoint of the
> alignment. We recommend performing this process in two iterations as a sequence
> may encompass multiple copies of the original fragment.

Uses uncompressed or compressed (.gz) FASTQ files as input.

Produces cleaned FASTQ files and, optionally, minimap2 output (.paf).

Main script: [`remove_palindrome.sh`](scripts/remove_palindrome.sh)

## Installation

See [INSTALL.md](INSTALL.md).

Tested on Ubuntu Linux 24.04.3, using bash v5.2.21, perl v5.38.2, and minimap2
v2.26-r1175.

## Usage

    $ remove_palindrome.sh [options] infile(s)

## Options and arguments

    -m <integer>   minimum fragment length to retain
    -c <integer>   number of CPUs for minimap2
    -h             print help message
    -p <string>    prefix for output files
    -k             no not remove intermediate files (keep)
    -v             print version
    infile(s)      one or several (ONT) fastq-formatted files

## Examples

    remove_palindrome.sh -h
    remove_palindrome.sh *.fastq.gz
    remove_palindrome.sh -m 1000 -c 4 -p 01 testfile.fastq

## Example

    $ ./scripts/remove_palindrome.sh data/testdata.fastq.gz

## Acknowledgements

Original scripts provided by [YiChien Lee](https://yichienlee1010.github.io/).

Additional functionality by Oleksandr Holovachov and Johan Nylander.

## License

[MIT License](LICENSE)

