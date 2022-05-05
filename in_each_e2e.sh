#!/usr/bin/env bash
set -o errexit -o nounset

# Run arguments passed in each e2e folder in serial
for dir in e2e/*; do
  if [[ -d "$dir" ]]; then
    (
      cd "$dir"
      echo -e "\n\n\n================================================================================"
      echo "$dir"
      echo -e "================================================================================\n"
      echo "+" "$@"
      "$@"
    )
  fi
done
