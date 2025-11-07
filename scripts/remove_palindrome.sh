#!/usr/bin/env bash

set -euo pipefail

# Defaults
version=0.1
min_len_default=1000
ncpu=$(getconf _NPROCESSORS_ONLN 2>/dev/null || \
       sysctl -n hw.logicalcpu 2>/dev/null || \
       echo 1) # fall back to '1' if check fails
script_name=$(basename "$0")
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
prefix=
mflag=
cflag=
pflag=
kflag=

function usage {
cat <<End_Of_Usage

$(basename "$0") version $version

Description:
  Filter palindromic reads in ONT fastq files

By:
  Oleksandr Holovachov, Johan Nylander

Usage:
  $(basename "$0") [options] infile(s)

Options and arguments:
  -m <integer>   minimum fragment length to retain
  -c <integer>   number of CPUs for minimap2
  -h             print help message
  -p <string>    prefix for output files
  -k             no not remove intermediate files (keep)
  -v             print version
  infile(s)      one or several (ONT) fastq-formatted files

Examples:
  $(basename "$0") -h
  $(basename "$0") *.fastq
  $(basename "$0") -m 1000 -c 8 -p 01 testfile.fastq

Notes:
  Requires
  - minimap2 (https://github.com/lh3/minimap2),
    tested using v2.26-r1175
  and helper (perl) scripts
  - fastq_partition_and_chop_palindrome.pl and
  - paf_identify_palindrome.pl
  The helper scripts needs to be placed in the same
  folder as the main script ($(basename "$0"))

  Based on scripts from https://yichienlee1010.github.io/script/

Copyright:

  MIT (https://choosealicense.com/licenses/mit/)

End_Of_Usage

}

# Check minimap2 (change path here manually if needed)
minimap="minimap2"
if ! command -v "$minimap" > /dev/null; then
  echo "$minimap can not be found in the PATH. Quitting."
  exit 1
else
  echo -n "==== Found minimap2 version"
  $minimap --version
fi

# Check helper scripts. Needs to be in the same folder as the main script.
#script_dir="$(dirname "$(readlink -f "$0")")"
pippl="$script_dir/paf_identify_palindrome.pl"
fpacppl="$script_dir/fastq_partition_and_chop_palindrome.pl"
for f in "$pippl" "$fpacppl"; do
  [[ -x "$f" ]] || { echo "Error: missing or non-executable helper $f" >&2; exit 1; }
done
echo "==== Found helper scripts"

while getopts 'm:c:p:kvh' OPTION ; do
  case $OPTION in
  m) mflag=1
     mval="$OPTARG"
     ;;
  c) cflag=1
     cval="$OPTARG"
     ;;
  p) pflag=1
     pval="$OPTARG"
     ;;
  k) kflag=1
     ;;
  v) echo -e "$(basename "$0") v$version"
     exit
     ;;
  h) usage
     exit
     ;;
  *) echo "Error: Unrecognized argument."
     usage
     exit
     ;;
  esac
done

shift $((OPTIND - 1))

infiles="$*" # put remaining args in infiles

if [ "$cflag" ] ; then
  if [[ $cval -gt $ncpu ]] ; then
    echo "Warning: Value for c is higher than logical cpu_max"
    echo "         Setting c to $ncpu"
    cpu=$ncpu
  else
    cpu=$cval
  fi
else
  cpu=$ncpu
fi

if [ "$mflag" ] ; then
  min_len=$mval
else
  min_len=$min_len_default
fi

if [ "$pflag" ] ; then
  prefix=$pval
fi

for infile in $infiles ; do
  is_gz=
  infile_bn=$(basename "$infile")
  echo "==== Processing $infile_bn"

  if [[ "$infile_bn" == *.gz ]] ; then
    is_gz=1
    base="${infile_bn%.*}" # remove .gz
    base="${base%.*}" # remove the previous extension
  else
    base="${infile_bn%.*}"
  fi

  if [ "$pflag" ] ; then
    paf1="$prefix.$base.minimap2.1.paf"
    list1="$prefix.$base.palinProp.1.list"
    log1="$prefix.$base.1.log"
  else
    paf1="$base.minimap2.1.paf"
    list1="$base.palinProp.1.list"
    log1="$base.1.log"
  fi

  # --- First iteration ---
  echo "==== First iteration: detect palindromes in $infile_bn"
  $minimap -t "$cpu" -x ava-ont "$infile" "$infile" | \
    tee "$paf1" | \
    "$pippl" > "$list1" 2> "$log1"
  if [ "$pflag" ]; then
    ln -s "$infile" "$prefix.$infile_bn"
    "$fpacppl" "$list1" "$prefix.$infile_bn" "$min_len"
  else
    "$fpacppl" "$list1" "$infile" "$min_len"
  fi

  # --- Second iteration on excluded reads ---
  if [ "$pflag" ] ; then
    paf2="$prefix.$base.minimap2.2.paf"
    list2="$prefix.$base.palinProp.2.list"
    log2="$prefix.$base.2.log"
    if [ "$is_gz" ] ; then
      exclude="$prefix.$base.exclude.fastq.gz"
    else
      exclude="$prefix.$base.exclude.fastq"
    fi
  else
    paf2="$base.minimap2.2.paf"
    list2="$base.palinProp.2.list"
    log2="$base.2.log"
    if [ "$is_gz" ] ; then
      exclude="$base.exclude.fastq.gz"
    else
      exclude="$base.exclude.fastq"
    fi
  fi

  if [[ -f "$exclude" ]]; then
    echo "=== Second iteration: detect palindromes in $exclude"
    $minimap -t "$cpu" -x ava-ont "$exclude" "$exclude" | \
      tee "$paf2" | \
      "$pippl" > "$list2" 2> "$log2"
    "$fpacppl" "$list2" "$exclude" "$min_len"
  else
    echo "==== No reads to process for second iteration (excluded FASTQ not found)."
  fi

  # --- Merge cleaned reads ---
  file_suffix="fastq"
  if [ "$is_gz" ]; then
    file_suffix="fastq.gz"
  fi

  if [ "$pflag" ] ; then
    include="$prefix.$base.include.$file_suffix"
    exclude1="$prefix.$base.exclude.exclude.$file_suffix"
    exclude2="$prefix.$base.exclude.include.$file_suffix"
    palindrome_treated="$prefix.$base.palindrome_treated.$file_suffix"
  else
    include="$base.include.$file_suffix"
    exclude1="$base.exclude.exclude.$file_suffix"
    exclude2="$base.exclude.include.$file_suffix"
    palindrome_treated="$base.palindrome_treated.$file_suffix"
  fi

  cat "$include" "$exclude1" "$exclude2" > "$palindrome_treated" 2>/dev/null
  if [ -e "$palindrome_treated" ] ; then
    echo "==== Palindrome-cleaned FASTQ generated: $palindrome_treated"
  else
    echo "Warning: Palindrome-cleaned file $palindrome_treated was not created"
    exit 1
  fi

  if [ ! $kflag ]; then
    echo "==== Removing intermediate files"

    if [ -h "$prefix.$infile_bn" ]; then
      rm "$prefix.$infile_bn"
    fi

    rm "$include" "$exclude" "$exclude1" "$exclude2" \
       "$paf1" "$paf2" "$list1" "$list2" \
       "$log1" "$log2"
  fi
done

echo -e "==== End of script $script_name"
