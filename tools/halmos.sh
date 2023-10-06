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

out=$(runlim --real-time-limit="${tout}" --kill-delay=2 --space-limit="${memout}" halmos --function "${fun_name}" --contract "${contract_name}" "$@" 2>&1)

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

if [[ $out =~ "Traceback" ]]; then
  exit 1
fi

if [[ $out =~ "[FAIL]" ]]; then
  echo "result: unsafe"
  exit 0
fi

if [[ $out =~ "[PASS]" ]]; then
  echo "result: safe"
  exit 0
fi

exit 1
