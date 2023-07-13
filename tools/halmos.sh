#!/usr/bin/env bash

set -x

contract_file="$1" ; shift
contract_name="$1" ; shift
fun_name="$1"; shift
ds_test="$1"; shift

out=$(halmos --ignore-compile --foundry-ignore-compile --function "${fun_name}" --contract "${contract_name}" "$@" 2>&1)

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
