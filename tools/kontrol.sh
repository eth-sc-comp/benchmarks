#!/usr/bin/env bash

set -x

contract_file="$1" ; shift
contract_name="$1" ; shift
fun_name="$1"; shift
sig="$1"; shift
ds_test="$1"; shift
tout="$1"; shift
memout="$1"; shift

rm -f ./*.smt2

# kontrol can't do symbolic storage yet
if [[ "${ds_test}" == "0" ]]; then
  echo "result: unknown"
  exit 0
fi

out=$(runlim --real-time-limit="${tout}" --kill-delay=2 --space-limit="${memout}" kontrol prove --counterexample-information --match-test "${contract_name}.${fun_name}" "$@" 2>&1)

# Check if we emitted smt2 files. If so, copy them over to a
# directory based on the contract file & name
shopt -s nullglob
set -- *.smt2
if [ "$#" -gt 0 ]; then
  dir="halmos-smt2/${contract_file}.${contract_name}/"
  mkdir -p "$dir"
  mv -f ./*.smt2 "$dir/"
fi

set +x

if [[ $out =~ "PROOF PASSED" ]]; then
  echo "result: safe"
  exit 0
fi

if [[ $out =~ "PROOF FAILED" ]] && [[ $out =~ "Model:" ]]; then
  echo "result: unsafe"
  exit 0
fi

if [[ $out =~ "PROOF FAILED" ]] && [[ $out =~ "Failed to generate a model" ]]; then
  echo "result: unknown"
  exit 0
fi

exit 1
