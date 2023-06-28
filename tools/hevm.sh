#!/usr/bin/env bash

set -x

contract_file="$1" ; shift
contract_name="$1" ; shift

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/utils.sh"

code=$(get_runtime_bytecode "${contract_file}" "${contract_name}")
out=$(hevm symbolic --code "$code" 2>& 1)

if [[ $out =~ "QED: No reachable property violations discovered" ]]; then
  echo "safe"
  exit 0
fi

if [[ $out =~ "Discovered the following counterexamples" ]]; then
  echo "unsafe"
  exit 0
fi

if [[ $out =~ "Could not determine reachability of the following end states" ]]; then
  echo "unknown"
  exit 0
fi

if [[ $out =~ "cannot delegateCall with symbolic target or context" ]]; then
  echo "unknown"
  exit 0
fi

exit 1
