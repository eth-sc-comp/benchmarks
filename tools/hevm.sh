#!/usr/bin/env bash

set -x

contract_file="$1" ; shift
contract_name="$1" ; shift
fun_name="$1"; shift
sig="$1"; shift
ds_test="$1"; shift
tout="$1"; shift
memout="$1"; shift
dump_smt="$1"; shift

extra_params=""
if [[ "$dump_smt" == "1" ]]; then
    extra_params="${extra_params} --smtdebug"
    rm -f ./*.smt2
fi


HEVM_BIN=hevm

rm -f ./*.smt2

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/utils.sh"

if [[ "${ds_test}" == "0" ]]; then
    code=$(get_runtime_bytecode "${contract_file}" "${contract_name}")
    out=$(runlim --real-time-limit="${tout}" --space-limit="${memout}" --kill-delay=2 "$HEVM_BIN" symbolic --code "${code}" --sig "${sig}" ${extra_params} "$@" 2>&1)
elif [[ "${ds_test}" == "1" ]]; then
    out=$(runlim --real-time-limit="${tout}" --space-limit="${memout}" --kill-delay=2 "$HEVM_BIN" test --match "${contract_file}.*${contract_name}.*${fun_name}" --verbose 2 ${extra_params} "$@" 2>&1)
else
    echo "Called incorrectly"
    exit 1
fi

# Check if we emitted smt2 files. If so, copy them over to a
# directory based on the contract file & name
if [[ "$dump_smt" == "1" ]]; then
    shopt -s nullglob
    set -- *.smt2
    if [ "$#" -gt 0 ]; then
      dir="hevm-smt2/${contract_file}.${contract_name}/"
      mkdir -p "$dir"
      mv -f ./*.smt2 "$dir/"
    fi
fi

set +x

if [[ $out =~ "hevm was only able to partially explore the given contract" ]]; then
  echo "unknown"
  exit 0
fi

if [[ $out =~ "No reachable assertion violations, but all branches reverted" ]]; then
  echo "result: safe"
  exit 0
fi

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
