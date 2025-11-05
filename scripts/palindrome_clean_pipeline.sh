#!/usr/bin/env bash

# Script:
#   palindrome_clean_pipeline.sh
# Description:
#   Detects and removes palindromic reads from ONT FASTQ using
#   minimap2 + Perl scripts. Produces cleaned FASTQs.
#   - Saves minimap2 output (.paf)
#   - Uses plain FASTQ files (no gzip)
# Usage:
#   ./palindrome_clean_pipeline.sh <FASTQ_file> <sample_ID> <CPU_threads> <min_frag_len>
# Example:
#   ./palindrome_clean_pipeline.sh reads.fastq Sample01 16 1000

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <FASTQ_file> <sample_ID> <CPU_threads> <min_frag_len>"
  exit 1
fi

SAMPLE=$1 # Input FASTQ
ID=$2     # Sample ID (used as output prefix)
CPU=$3    # Number of threads
MINLEN=$4 # Minimum fragment length to retain

# Check presence of minimap2, paf_identify_palindrom.pl, fastq_partition_and_chop_palindrome.pl
command -v minimap2 > /dev/null 2>&1 || { echo >&2 "Error: minimap2 not found."; exit 1; }
command -v ./paf_identify_palindrome.pl > /dev/null 2>&1 || { echo >&2 "Error: ./paf_identify_palindrom.pl not found."; exit 1; }
command -v./fastq_partition_and_chop_palindrome.pl > /dev/null 2>&1 || { echo >&2 "Error: minimap2 not found."; exit 1; }

# --- First iteration ---
echo "=== First iteration: detect palindromes in $SAMPLE ==="
minimap2 -t "$CPU" -x ava-ont "$SAMPLE" "$SAMPLE" | \
  tee "$ID.minimap2.1stIte.paf" | \
  ./paf_identify_palindrome.pl > "$ID.palimProp.1stIte.list" 2> "$ID.1stIte.log"

./fastq_partition_and_chop_palindrome.pl "$ID.palimProp.1stIte.list" "$SAMPLE" "$MINLEN"

# --- Second iteration on excluded reads ---
EXCLUDE="${SAMPLE}.exclude.fastq"
if [[ -f "$EXCLUDE" ]]; then
  echo "=== Second iteration: detect palindromes in $EXCLUDE ==="
  minimap2 -t "$CPU" -x ava-ont "$EXCLUDE" "$EXCLUDE" | \
    tee "$ID.minimap2.2ndIte.paf" | \
    ./paf_identify_palindrome.pl > "$ID.palimProp.2ndIte.list" 2> "$ID.2ndIte.log"

  ./fastq_partition_and_chop_palindrome.pl "$ID.palimProp.2ndIte.list" "$EXCLUDE" "$MINLEN"
else
  echo "No reads to process for second iteration (excluded FASTQ not found)."
fi

# --- Merge cleaned reads ---
INCLUDE="${SAMPLE}.include.fastq"
EXCLUDE1="${EXCLUDE}.exclude.fastq"
EXCLUDE2="${EXCLUDE}.include.fastq"

echo "=== Merging cleaned FASTQ files ==="
cat "$INCLUDE" "$EXCLUDE1" "$EXCLUDE2" 2>/dev/null > "$ID.palindrome_treated.fastq"

echo "Palindrome-cleaned FASTQ generated: $ID.palindrome_treated.fastq"

