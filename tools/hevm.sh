#!/usr/bin/env bash

set -x

contract_file="$1" ; shift
contract_name="$1" ; shift
fun_name="$1"; shift
ds_test="$1"; shift
tout="$1"; shift

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/utils.sh"

if [[ "${ds_test}" == "0" ]]; then
    code=$(get_runtime_bytecode "${contract_file}" "${contract_name}")
    out=$(doalarm -t real "${tout}" hevm symbolic --code "${code}" "$@")
elif [[ "${ds_test}" == "1" ]]; then
    out=$(doalarm -t real "${tout}" hevm test --match "${contract_file}.*${fun_name}" "$@")
else
    echo "Called incorrectly"
    exit 1
fi

set +x

if [[ $out =~ "[FAIL]" ]]; then
  echo "result: unsafe"
  exit 0
fi

if [[ $out =~ "[PASS]" ]]; then
  echo "result: safe"
  exit 0
fi

if [[ $out =~ "QED: No reachable property violations discovered" ]]; then
  echo "result: safe"
  exit 0
fi

if [[ $out =~ "Discovered the following counterexamples" ]]; then
  echo "result: unsafe"
  exit 0
fi

if [[ $out =~ "Could not determine reachability of the following end states" ]]; then
  echo "result: unknown"
  exit 0
fi

if [[ $out =~ "cannot delegateCall with symbolic target or context" ]]; then
  echo "result: unknown"
  exit 0
fi

exit 1
