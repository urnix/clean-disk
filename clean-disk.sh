#!/bin/bash

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 path_to_source_folder path_to_duplicates_folder [-s] [-e exclude_path...]"
    echo "-s: Print statistics only, do not move files."
    echo "-e: Exclude paths from processing. Can be used multiple times for different paths."
    exit 1
fi

search_dir="$1"
duplicates_dir="$2"
stat_mode=false
declare -a exclude_patterns

while getopts "se:" opt; do
  case $opt in
    s) stat_mode=true ;;
    e) exclude_patterns+=("$OPTARG") ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done

mkdir -p "$duplicates_dir"

echo $stat_mode

fdupes -rn "$search_dir" > duplicates.txt

if [ "$stat_mode" = true ]; then
    echo "Statistics mode: Displaying duplicate file statistics only."
    if [ -n "$exclude_pattern" ]; then
        awk -v pat="$exclude_pattern" '$0 !~ pat {if ($0 !~ /^$/){if (prev != $0) skip=1; if (skip) print $0;} else skip=0; prev=$0}' duplicates.txt | sort | uniq -c
    else
        awk 'NF{if ($0 !~ /^$/){if (prev != $0) skip=1; if (skip) print $0;} else skip=0; prev=$0}' duplicates.txt | sort | uniq -c
    fi
else
    echo "Moving duplicate files to: $duplicates_dir"
    if [ -n "$exclude_pattern" ]; then
        awk -v pat="$exclude_pattern" '$0 !~ pat {if ($0 !~ /^$/){if (prev != $0) skip=1; if (skip) print $0;} else skip=0; prev=$0}' duplicates.txt | \
        while IFS= read -r file; do
            mv "$file" "$duplicates_dir" 2>>too_long.txt || echo "$file" >> too_long.txt
        done
    else
        awk 'NF{if ($0 !~ /^$/){if (prev != $0) skip=1; if (skip) print $0;} else skip=0; prev=$0}' duplicates.txt | \
        while IFS= read -r file; do
            mv "$file" "$duplicates_dir" 2>>too_long.txt || echo "$file" >> too_long.txt
        done
    fi
fi

echo "Done"
