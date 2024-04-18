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

shift 2  # Shift past the first two mandatory arguments

while (( "$#" )); do
  case "$1" in
    -s)
      stat_mode=true
      shift
      ;;
    -e)
      exclude_patterns+=("$2")
      shift 2
      ;;
    *)
      echo "Invalid option $1" >&2
      exit 1
      ;;
  esac
done


# Combine exclude patterns into one regex
exclude_regex=$(IFS='|'; echo "${exclude_patterns[*]}")

echo "Stat mode: $stat_mode"
echo "Excluded paths: ${exclude_patterns[*]}"




mkdir -p "$duplicates_dir"


fdupes -rn "$search_dir" > duplicates.txt

if [ "$stat_mode" = true ]; then
    echo "Statistics mode: Displaying duplicate file statistics only."
    awk -v pat="$exclude_regex" '$0 !~ pat && NF{if ($0 !~ /^$/){if (prev != $0) skip=1; if (skip) print $0;} else skip=0; prev=$0}' duplicates.txt | sort | uniq -c
#else
#    echo "Moving duplicate files to: $duplicates_dir"
#    awk -v pat="$exclude_regex" '$0 !~ pat && NF{if ($0 !~ /^$/){if (prev != $0) skip=1; if (skip) print $0;} else skip=0; prev=$0}' duplicates.txt | \
#    while IFS= read -r file; do
#        mv "$file" "$duplicates_dir" 2>>too_long.txt || echo "$file" >> too_long.txt
#    done
fi

echo "Done"
