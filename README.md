# FASTQ Palindrome Cleaning Pipeline

- Last modified: 2025-11-07 19:12:07
- Sign: Johan Nylander

## Description

Detects and removes palindromic reads from [ONT
FASTQ](https://epi2me.nanoporetech.com/notebooks/Introduction_to_fastq_file.html)
using [minimap2](https://github.com/lh3/minimap2) + Perl scripts.

Uses plain or compressed (.gz) FASTQ files as input.

Produces cleaned FASTQ files and, optionally, minimap2 output (.paf).

Main script: [`remove_palindrome.sh`](scripts/remove_palindrome.sh)

## Installation

See [INSTALL](INSTALL).

Tested on Ubuntu 24.04.3, using bash v5.2.21, perl v5.38.2, and minimap2 v2.26-r1175.

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
    remove_palindrome.sh *.fastq
    remove_palindrome.sh -m 1000 -c 8 -p 01 testfile.fastq

## Example

    $ ./scripts/remove_palindrome.sh data/testdata.fastq

## Acknowledgements

Original scripts provided by [YiChien Lee](https://yichienlee1010.github.io/script/).

## License

[MIT License](LICENSE)

