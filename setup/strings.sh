#!/bin/bash

set -efu -o pipefail

# Remove double quotes from prefix and suffix of a string
__remove_trailing_double_quotes() {
  local string=""
  if [ $# -ge 1 ]
  then
    string="$1"
  fi

  sed -e 's/^"//' -e 's/"$//' <<<"$string"
}
