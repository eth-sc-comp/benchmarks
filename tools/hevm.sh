#!/usr/bin/env bash

set -x

contract_file="$1" ; shift
contract_name="$1" ; shift
fun_name="$1"; shift
ds_test="$1"; shift

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/utils.sh"

if [[ "${ds_test}" == "0" ]]; then
    code=$(get_runtime_bytecode "${contract_file}" "${contract_name}")
    out=$(hevm symbolic --code "$code" 2>& 1)
elif [[ "${ds_test}" == "1" ]]; then
    out=$(hevm test --match "${contract_file}.*${fun_name}")
else
    echo "Called incorrectly"
    exit 1
fi

if [[ $out =~ "[FAIL]" ]]; then
  echo "unsafe"
  exit 0
fi

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
