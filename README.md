# Palindrome Clean Pipeline

- Last modified: 2025-11-05 11:39:17
- Sign: Johan Nylander

## Description

Detects and removes palindromic reads from [ONT
FASTQ](https://epi2me.nanoporetech.com/notebooks/Introduction_to_fastq_file.html)
using [minimap2](https://github.com/lh3/minimap2) + Perl scripts.

Uses plain or compressed (.gz) FASTQ files as input.

Produces cleaned FASTQ files and minimap2 output (.paf).

Main script: [`palindrome_clean_pipeline.sh`](scripts/palindrome_clean_pipeline.sh)

## Installation

See [INSTALL](INSTALL).

Tested on Ubuntu 24.04.3, using bash v5.2.21, perl v5.38.2, and minimap2 v2.26-r1175.

## Usage

    $ palindrome_clean_pipeline.sh <FASTQ_file> <sample_ID> <CPU_threads> <min_frag_len>

## Options

- `FASTQ_file` -- **description here of the expected input format!**
- `sample_ID` -- **description here of the expected input format!**
- `CPU_threads` -- **description here of the expected input format!**
- `min_frag_len` -- **description here of the expected input format!**

## Example

    $ ./scripts/palindrome_clean_pipeline.sh data/reads.fastq Sample01 16 1000

## Acknowledgements

Original scripts provided by [YiChien Lee](https://yichienlee1010.github.io/script/).

## License

[MIT License](LICENSE)

